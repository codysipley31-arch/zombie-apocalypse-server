local QBCore = exports['qb-core']:GetCoreObject()

local sprinting = {}    -- [src] = number of sprint samples this tick

local function clamp(v) return math.max(0.0, math.min(100.0, v)) end

local function getNeeds(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    local md = Player.PlayerData.metadata
    return md.hunger or Config.StartValue, md.thirst or Config.StartValue, Player
end

local function setNeeds(src, hunger, thirst)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    hunger, thirst = clamp(hunger), clamp(thirst)
    Player.Functions.SetMetaData('hunger', hunger)
    Player.Functions.SetMetaData('thirst', thirst)
    TriggerClientEvent('survival-needs:client:needs', src, hunger, thirst)
end

---------------------------------------------------------------------- lifecycle

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(3000, function()
        local h, t = getNeeds(src)
        if h then setNeeds(src, h, t) end
    end)
end)

RegisterNetEvent('survival-needs:server:sprintSample', function()
    sprinting[source] = (sprinting[source] or 0) + 1
end)

CreateThread(function()
    while true do
        Wait(Config.Tick * 1000)
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local h, t, Player = getNeeds(src)
            if Player and not Player.PlayerData.metadata.isdead then
                local mult = 1.0
                -- client samples roughly every 5 s while sprinting
                if (sprinting[src] or 0) >= 3 then mult = Config.SprintExtra end
                sprinting[src] = 0
                setNeeds(src, h - Config.Decay.hunger * mult, t - Config.Decay.thirst * mult)
            end
        end
    end
end)

AddEventHandler('playerDropped', function() sprinting[source] = nil end)

---------------------------------------------------------------------- items

-- ox_inventory export for food/water/medical items.
exports('consume', function(event, item, inventory)
    if event ~= 'usedItem' then return end
    local src = inventory.id
    local effect = Config.Consumables[item.name]
    if not effect then return end

    if effect.hunger or effect.thirst then
        local h, t = getNeeds(src)
        if h then setNeeds(src, h + (effect.hunger or 0), t + (effect.thirst or 0)) end
    end

    if effect.heal then
        TriggerClientEvent('survival-needs:client:heal', src, effect.heal, effect.hot or 0, effect.bleed)
    end
end)

---------------------------------------------------------------------- death & respawn

local deathTimes = {}

RegisterNetEvent('survival-needs:server:died', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or deathTimes[src] then return end
    deathTimes[src] = os.time()
    Player.Functions.SetMetaData('isdead', true)

    if not Config.Death.dropInventory then return end

    local keep = {}
    for _, name in ipairs(Config.Death.keepItems) do keep[name] = true end

    local drop = {}
    for _, slot in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
        if slot and slot.name and not keep[slot.name] then
            drop[#drop + 1] = { slot.name, slot.count, slot.metadata }
        end
    end
    if #drop == 0 then return end

    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    exports.ox_inventory:CustomDrop(Config.Death.bagLabel, drop, vec3(c.x, c.y, c.z - 0.9))

    if next(keep) then
        exports.ox_inventory:ClearInventory(src, keep)
    else
        exports.ox_inventory:ClearInventory(src)
    end
end)

lib.callback.register('survival-needs:server:respawn', function(src)
    local started = deathTimes[src]
    if not started then return nil end
    if os.time() - started < Config.Death.respawnSeconds - 2 then return nil end   -- small clock slack
    deathTimes[src] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    Player.Functions.SetMetaData('isdead', false)
    setNeeds(src, Config.RespawnValue, Config.RespawnValue)
    return Config.Respawns[math.random(#Config.Respawns)]
end)

AddEventHandler('playerDropped', function() deathTimes[source] = nil end)

-- Admin helper
lib.addCommand('revive', { help = 'Admin: revive a player', params = { { name = 'id', type = 'playerId', optional = true } } },
    function(src, args)
        if src ~= 0 and not QBCore.Functions.HasPermission(src, 'admin') then return end
        local t = args.id or src
        local Player = QBCore.Functions.GetPlayer(t)
        if Player then Player.Functions.SetMetaData('isdead', false) end
        deathTimes[t] = nil
        TriggerClientEvent('survival-needs:client:revive', t)
    end)

exports('SetNeeds', setNeeds)
exports('GetNeeds', getNeeds)
