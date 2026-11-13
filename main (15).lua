local QBCore = exports['qb-core']:GetCoreObject()

local lastHit = {}      -- [playerSrc] = os.clock ms of last accepted hit
local killedSeen = {}   -- [netId] = true (kill loot only paid once per zombie)

---------------------------------------------------------------------- clock

CreateThread(function()
    GlobalState.worldMinutes = Config.Time.startHour * 60
    if not Config.Time.enabled then return end
    while true do
        Wait(Config.Time.msPerMinute)
        GlobalState.worldMinutes = (GlobalState.worldMinutes + 1) % 1440
    end
end)

exports('GetSafeZones', function() return Config.SafeZones end)

---------------------------------------------------------------------- noise

RegisterNetEvent('zombie-ai:server:noise', function(coords)
    local src = source
    if type(coords) ~= 'vector3' then return end
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - coords) > 15.0 then return end
    for _, id in ipairs(GetPlayers()) do
        local p = GetPlayerPed(id)
        if p ~= 0 and #(GetEntityCoords(p) - coords) < 160.0 then
            TriggerClientEvent('zombie-ai:client:noise', tonumber(id), coords)
        end
    end
end)

-- Other resources (hordes, supply drops, base alarms) can call this
exports('Alert', function(coords)
    for _, id in ipairs(GetPlayers()) do
        local p = GetPlayerPed(id)
        if p ~= 0 and #(GetEntityCoords(p) - coords) < 200.0 then
            TriggerClientEvent('zombie-ai:client:noise', tonumber(id), coords)
        end
    end
end)

---------------------------------------------------------------------- hits

RegisterNetEvent('zombie-ai:server:hit', function(zombieNetId, targetSrc)
    local src = source
    if type(zombieNetId) ~= 'number' or type(targetSrc) ~= 'number' then return end

    local zEnt = NetworkGetEntityFromNetworkId(zombieNetId)
    if not zEnt or zEnt == 0 or not DoesEntityExist(zEnt) then return end
    if not Entity(zEnt).state.zombie then return end

    local tPed = GetPlayerPed(targetSrc)
    if tPed == 0 then return end
    if #(GetEntityCoords(zEnt) - GetEntityCoords(tPed)) > Config.Attack.maxServerRange then return end

    -- per-victim rate limit so a modified client cannot machine-gun damage
    local now = GetGameTimer()
    if lastHit[targetSrc] and now - lastHit[targetSrc] < Config.Attack.cooldown * 0.6 then return end
    lastHit[targetSrc] = now

    local nightF = ZUtil.nightFactor(ZUtil.hour())
    local dmg = math.floor(Config.Attack.damage * ZUtil.lerp(1.0, Config.Night.damageMult, nightF))
    TriggerClientEvent('zombie-ai:client:damage', targetSrc, dmg, math.random() < 0.12)

    -- survival/infection resources listen to this
    TriggerEvent('zombie-ai:bitten', targetSrc, zombieNetId, dmg)
end)

---------------------------------------------------------------------- kill loot

local function rollLoot(src)
    local kl = Config.KillLoot
    if math.random() > kl.chance then return end
    local rolls = math.random(kl.rolls.min, kl.rolls.max)
    for _ = 1, rolls do
        local entry = ZUtil.pickWeighted(kl.table)
        local count = math.random(entry.min, entry.max)
        if exports.ox_inventory:CanCarryItem(src, entry.name, count) then
            exports.ox_inventory:AddItem(src, entry.name, count)
        end
    end
end

RegisterNetEvent('zombie-ai:server:killed', function(zombieNetId)
    local src = source
    if type(zombieNetId) ~= 'number' or killedSeen[zombieNetId] then return end

    local zEnt = NetworkGetEntityFromNetworkId(zombieNetId)
    if not zEnt or zEnt == 0 or not DoesEntityExist(zEnt) then return end
    if not Entity(zEnt).state.zombie then return end

    local pPed = GetPlayerPed(src)
    if pPed == 0 or #(GetEntityCoords(zEnt) - GetEntityCoords(pPed)) > 80.0 then return end

    killedSeen[zombieNetId] = true
    SetTimeout(120000, function() killedSeen[zombieNetId] = nil end)

    rollLoot(src)
    TriggerEvent('zombie-ai:zombieKilled', src, zombieNetId)
end)

AddEventHandler('playerDropped', function()
    lastHit[source] = nil
end)

---------------------------------------------------------------------- admin

local function isAdmin(src)
    return src == 0 or QBCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')
end

lib.addCommand('zcoords', { help = 'Admin: copy your coordinates', restricted = false }, function(src)
    if not isAdmin(src) then return end
    TriggerClientEvent('zombie-ai:client:printCoords', src)
end)

lib.addCommand('zclear', { help = 'Admin: delete all zombies' }, function(src)
    if not isAdmin(src) then return end
    local n = 0
    for _, ent in ipairs(GetAllPeds()) do
        if Entity(ent).state.zombie then
            DeleteEntity(ent)
            n = n + 1
        end
    end
    print(('[zombie-ai] %d zombies cleared by %s'):format(n, GetPlayerName(src) or 'console'))
end)

lib.addCommand('settime', { help = 'Admin: set world hour', params = { { name = 'hour', type = 'number' } } },
    function(src, args)
        if not isAdmin(src) then return end
        GlobalState.worldMinutes = math.floor((args.hour % 24) * 60)
    end)
