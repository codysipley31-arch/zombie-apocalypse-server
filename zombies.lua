-- Zombie spawning, detection, chase, attack and cleanup.
-- Each client owns the zombies it spawns (OneSync entity ownership). If the owner
-- leaves, another nearby client adopts them via the `zombie` state bag flag.

local zombies = {}          -- [ped] = data
local zombieCount = 0
local players = {}          -- cached nearby player info, refreshed every second
local noise = { until_ = 0, coords = nil }
local zombieGroup = `ZOMBIE_GROUP`
local HEAD_BONE = 31086
local attackDictLoaded = false

---------------------------------------------------------------------- helpers

local function dbg(...)
    if Config.Debug then print('[zombie-ai]', ...) end
end

local function setupRelationships()
    AddRelationshipGroup('ZOMBIE_GROUP')
    SetRelationshipBetweenGroups(0, zombieGroup, zombieGroup)
end

local function refreshPlayers()
    local list = {}
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= 0 and not IsEntityDead(ped) then
            local c = GetEntityCoords(ped)
            if not ZUtil.inSafeZone(c) then
                list[#list + 1] = {
                    pid = pid,
                    src = GetPlayerServerId(pid),
                    ped = ped,
                    coords = c,
                    speed = GetEntitySpeed(ped),
                    inVeh = IsPedInAnyVehicle(ped, false),
                    stealth = GetPedStealthMovement(ped),
                }
            end
        end
    end
    players = list
end

local function allPlayerCoords()
    local out = {}
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= 0 then out[#out + 1] = GetEntityCoords(ped) end
    end
    return out
end

local function nearestDistance(coords, list)
    local best = 1e9
    for i = 1, #list do
        local d = #(coords - list[i])
        if d < best then best = d end
    end
    return best
end

local function deleteZombie(ped)
    zombies[ped] = nil
    zombieCount = math.max(0, zombieCount - 1)
    if DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeletePed(ped)
    end
end

---------------------------------------------------------------------- spawning

local function configureZombie(ped, runner)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, zombieGroup)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanRagdoll(ped, true)
    SetPedConfigFlag(ped, 281, true)           -- no writhe
    SetPedSuffersCriticalHits(ped, true)
    SetPedDiesWhenInjured(ped, true)
    SetPedKeepTask(ped, true)
    DisablePedPainAudio(ped, true)
    StopPedSpeaking(ped, true)
    SetPedMaxHealth(ped, Config.ZombieHealth)
    SetEntityHealth(ped, Config.ZombieHealth)
    SetPedArmour(ped, 0)
    SetPedPathCanUseClimbovers(ped, true)
    SetPedPathCanUseLadders(ped, false)
    SetPedPathAvoidFire(ped, false)

    -- Random mess: damage the visual look a little
    SetPedRandomComponentVariation(ped, 0)

    if not runner then
        local style = Config.WalkStyles[math.random(#Config.WalkStyles)]
        lib.requestAnimSet(style)
        SetPedMovementClipset(ped, style, 0.25)
    end

    Entity(ped).state:set('zombie', true, true)
end

---@param coords vector3
---@param opts? { rally?: vector3, runner?: boolean, model?: string }
local function spawnZombie(coords, opts)
    opts = opts or {}
    local modelName = opts.model or Config.Models[math.random(#Config.Models)]
    local model = joaat(modelName)
    if not lib.requestModel(model, 5000) then return nil end

    local nightF = ZUtil.nightFactor(ZUtil.hour())
    local runner = opts.runner
    if runner == nil then
        runner = (math.random() < Config.Night.runnerChance * nightF)
    end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    if not ped or ped == 0 then return nil end

    configureZombie(ped, runner)

    zombies[ped] = {
        state = 'wander',
        runner = runner,
        spawnedAt = GetGameTimer(),
        nextAttack = 0,
        lastTask = 0,
        busyUntil = 0,
        rally = opts.rally,
        target = nil,
        dead = nil,
    }
    zombieCount = zombieCount + 1
    return ped
end

local function findSpawnPoint(playerCoords, allCoords)
    local sp = Config.Spawn
    local angle = math.random() * 2.0 * math.pi
    local dist = sp.minDist + math.random() * (sp.maxDist - sp.minDist)
    local x = playerCoords.x + math.cos(angle) * dist
    local y = playerCoords.y + math.sin(angle) * dist

    RequestCollisionAtCoord(x, y, playerCoords.z)
    local found, z = GetGroundZFor_3dCoord(x, y, playerCoords.z + 40.0, false)
    if not found then return nil end

    local p = vec3(x, y, z)
    local water, wz = GetWaterHeight(x, y, z)
    if water and wz > z - 0.5 then return nil end
    if ZUtil.inSafeZone(p, 15.0) then return nil end

    -- never pop in right next to any player, nor in plain view at mid range
    if nearestDistance(p, allCoords) < sp.minDist then return nil end
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z + 1.0)
    if onScreen and sx > 0.0 and sx < 1.0 and sy > 0.0 and sy < 1.0 and dist < 80.0 then
        return nil
    end
    return p
end

CreateThread(function()
    setupRelationships()
    Wait(2000)
    while true do
        Wait(Config.Spawn.interval)
        local ped = PlayerPedId()
        if not IsEntityDead(ped) and not ZUtil.inSafeZone(GetEntityCoords(ped)) then
            local sp = Config.Spawn
            local nightF = ZUtil.nightFactor(ZUtil.hour())
            local cap = sp.maxPerPlayer * ZUtil.lerp(1.0, Config.Night.spawnMult, nightF)

            local pc = GetEntityCoords(ped)
            local nearby = 0
            for i = 1, #players do
                if players[i].ped ~= ped and #(players[i].coords - pc) < 120.0 then nearby = nearby + 1 end
            end
            cap = math.floor(cap * (1.0 + sp.groupScale * math.min(nearby, 2)))

            local poolSize = #GetGamePool('CPed')
            if zombieCount < cap and poolSize < sp.pedPoolLimit then
                local coordsAll = allPlayerCoords()
                local spawned = 0
                local tries = 0
                while spawned < sp.perCycle and zombieCount < cap and tries < 8 do
                    tries = tries + 1
                    local p = findSpawnPoint(pc, coordsAll)
                    if p and spawnZombie(p) then spawned = spawned + 1 end
                end
            end
        end
    end
end)

---------------------------------------------------------------------- AI

local function hearRange(pl)
    local d = Config.Detect
    if pl.inVeh and pl.speed > 3.0 then return d.hearVehicle end
    if pl.stealth then return d.hearSneak end
    if pl.speed > 3.5 then return d.hearRun end
    if pl.speed > 0.6 then return d.hearWalk end
    return 2.5
end

local function pickTarget(zped, zc, sight)
    local best, bestD, bestHeard = nil, 1e9, false
    for i = 1, #players do
        local pl = players[i]
        local d = #(pl.coords - zc)
        if d < bestD then
            local heard = d <= hearRange(pl)
            local seen = d <= sight and HasEntityClearLosToEntity(zped, pl.ped, 17)
            if heard or seen then best, bestD, bestHeard = pl, d, heard end
        end
    end
    return best, bestD
end

local function handleHeadshot(ped)
    if not Config.HeadshotInstantKill then return end
    if HasEntityBeenDamagedByAnyPed(ped) then
        local ok, bone = GetPedLastDamageBone(ped)
        if ok and bone == HEAD_BONE then
            SetEntityHealth(ped, 0)
        end
        ClearPedLastDamageBone(ped)
        ClearEntityLastDamageEntity(ped)
    end
end

local function chase(ped, z, targetPed, now)
    if z.state ~= 'chase' or z.target ~= targetPed or now - z.lastTask > 1500 then
        z.state, z.target, z.lastTask = 'chase', targetPed, now
        TaskGoToEntity(ped, targetPed, -1, 0.9, z.runner and 2.0 or 1.0, 0, 0)
    end
end

local function investigate(ped, z, coords, now)
    if z.state ~= 'investigate' or now - z.lastTask > 4000 then
        z.state, z.target, z.lastTask = 'investigate', nil, now
        TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, z.runner and 2.0 or 1.0, 20000, 0.0, 0.5)
    end
end

local function wander(ped, z, now)
    if z.rally then
        if #(GetEntityCoords(ped) - z.rally) < 18.0 then
            z.rally = nil
        elseif z.state ~= 'rally' or now - z.lastTask > 6000 then
            z.state, z.lastTask = 'rally', now
            TaskGoStraightToCoord(ped, z.rally.x, z.rally.y, z.rally.z, 1.0, 12000, 0.0, 2.0)
            return
        else
            return
        end
    end
    if z.state ~= 'wander' or now - z.lastTask > Config.Wander.idleMs then
        z.state, z.target, z.lastTask = 'wander', nil, now
        TaskWanderStandard(ped, 10.0, 10)
    end
end

local function attack(ped, z, pl, now)
    z.nextAttack = now + Config.Attack.cooldown
    z.busyUntil = now + 750
    z.lastTask = 0
    TaskTurnPedToFaceEntity(ped, pl.ped, 300)
    if not attackDictLoaded then
        attackDictLoaded = lib.requestAnimDict(Config.Attack.dict, 3000) and true or false
    end
    if attackDictLoaded then
        TaskPlayAnim(ped, Config.Attack.dict, Config.Attack.clip, 8.0, -8.0, 700, 48, 0.0, false, false, false)
    end
    TriggerServerEvent('zombie-ai:server:hit', NetworkGetNetworkIdFromEntity(ped), pl.src)
end

CreateThread(function()
    while true do
        Wait(400)
        refreshPlayers()
        local now = GetGameTimer()
        local hour = ZUtil.hour()
        local nightF = ZUtil.nightFactor(hour)
        local sight = ZUtil.lerp(Config.Detect.sightDay, Config.Detect.sightNight, nightF)
        local rate = ZUtil.lerp(Config.Night.speedDay, Config.Night.speedNight, nightF)
        local allCoords = allPlayerCoords()
        local noiseActive = noise.coords and now < noise.until_

        for ped, z in pairs(zombies) do
            if not DoesEntityExist(ped) then
                zombies[ped] = nil
                zombieCount = math.max(0, zombieCount - 1)
            elseif not NetworkHasControlOfEntity(ped) then
                -- ownership moved; the new owner adopts via the state bag scan
                zombies[ped] = nil
                zombieCount = math.max(0, zombieCount - 1)
            elseif IsPedDeadOrDying(ped, true) then
                if not z.dead then
                    z.dead = now
                    if GetPedSourceOfDeath(ped) == PlayerPedId() then
                        TriggerServerEvent('zombie-ai:server:killed', NetworkGetNetworkIdFromEntity(ped))
                    end
                elseif now - z.dead > Config.Spawn.corpseMs then
                    deleteZombie(ped)
                end
            else
                handleHeadshot(ped)
                local zc = GetEntityCoords(ped)

                if nearestDistance(zc, allCoords) > Config.Spawn.despawnDist or ZUtil.inSafeZone(zc) then
                    deleteZombie(ped)
                elseif now >= z.busyUntil then
                    SetPedMoveRateOverride(ped, z.runner and 1.0 or rate)
                    local target, d = pickTarget(ped, zc, sight)

                    if target then
                        if d <= Config.Attack.range and now >= z.nextAttack then
                            attack(ped, z, target, now)
                        else
                            chase(ped, z, target.ped, now)
                        end
                    elseif z.state == 'chase' and z.target and DoesEntityExist(z.target)
                        and #(GetEntityCoords(z.target) - zc) < sight * Config.Detect.loseFactor then
                        -- lost sight briefly: keep following until they get far enough away
                        chase(ped, z, z.target, now)
                    elseif noiseActive and #(noise.coords - zc) < 120.0 then
                        investigate(ped, z, noise.coords, now)
                    else
                        wander(ped, z, now)
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------------------- adoption

CreateThread(function()
    while true do
        Wait(3000)
        for _, ped in ipairs(GetGamePool('CPed')) do
            if not zombies[ped] and not IsPedAPlayer(ped) and NetworkGetEntityIsNetworked(ped)
                and NetworkHasControlOfEntity(ped) and Entity(ped).state.zombie then
                zombies[ped] = {
                    state = 'wander', runner = false, spawnedAt = GetGameTimer(),
                    nextAttack = 0, lastTask = 0, busyUntil = 0,
                    dead = IsPedDeadOrDying(ped, true) and GetGameTimer() or nil,
                }
                zombieCount = zombieCount + 1
            end
        end
    end
end)

---------------------------------------------------------------------- events / exports

RegisterNetEvent('zombie-ai:client:noise', function(coords)
    noise.coords = coords
    noise.until_ = GetGameTimer() + Config.Detect.alertMs
end)

RegisterNetEvent('zombie-ai:client:damage', function(dmg, ragdoll)
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end
    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - dmg))
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.12)
    if ragdoll then SetPedToRagdoll(ped, 900, 900, 0, false, false, false) end
end)

exports('SpawnZombie', spawnZombie)
exports('GetZombieCount', function() return zombieCount end)
exports('Alert', function(coords)
    noise.coords = coords
    noise.until_ = GetGameTimer() + Config.Detect.alertMs
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for ped in pairs(zombies) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
end)
