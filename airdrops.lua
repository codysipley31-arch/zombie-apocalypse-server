local active = {}    -- [id] = { drop, blip, area, obj, fx }

local SPAWN_DIST = 220.0

local function cleanup(id)
    local a = active[id]
    if not a then return end
    if a.blip then RemoveBlip(a.blip) end
    if a.area then RemoveBlip(a.area) end
    if a.fx then StopParticleFxLooped(a.fx, false) end
    if a.obj and DoesEntityExist(a.obj) then
        exports['qb-target']:RemoveTargetEntity(a.obj)
        DeleteEntity(a.obj)
    end
    active[id] = nil
end

local function spawnCrate(id, a)
    local model = joaat(Config.Airdrops.crateModel)
    if not lib.requestModel(model, 5000) then return end
    local c = a.drop.coords
    RequestCollisionAtCoord(c.x, c.y, c.z)
    local found, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 60.0, false)
    local z = found and gz or c.z
    local obj = CreateObject(model, c.x, c.y, z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    a.obj = obj

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(10) end
    UseParticleFxAsset('core')
    a.fx = StartParticleFxLoopedAtCoord('exp_grd_flare', c.x, c.y, z + 0.5, 0.0, 0.0, 0.0, 2.5, false, false, false, false)
    SetParticleFxLoopedColour(a.fx, 1.0, 0.15, 0.1, false)

    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type = 'client',
                icon = 'fas fa-parachute-box',
                label = 'Open Supply Drop',
                action = function()
                    if lib.callback.await('survival-looting:server:openDrop', false, id) then
                        exports.ox_inventory:openInventory('stash', 'airdrop_' .. id)
                    else
                        lib.notify({ type = 'error', description = 'Too far away.' })
                    end
                end,
            },
        },
        distance = 2.5,
    })
end

local function register(drop)
    if active[drop.id] then return end
    local a = { drop = drop }
    active[drop.id] = a

    a.area = AddBlipForRadius(drop.blip.x, drop.blip.y, drop.blip.z, 150.0)
    SetBlipColour(a.area, 1)
    SetBlipAlpha(a.area, 90)

    a.blip = AddBlipForCoord(drop.blip.x, drop.blip.y, drop.blip.z)
    SetBlipSprite(a.blip, 94)
    SetBlipColour(a.blip, 1)
    SetBlipScale(a.blip, 0.9)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Supply Drop')
    EndTextCommandSetBlipName(a.blip)
end

RegisterNetEvent('survival-looting:client:airdrop', function(drop)
    register(drop)
    lib.notify({
        title = 'Supply Drop',
        description = 'A plane roars overhead. Something landed nearby. Expect company.',
        type = 'warning',
        duration = 9000,
    })
end)

RegisterNetEvent('survival-looting:client:airdropEnd', function(id)
    cleanup(id)
end)

CreateThread(function()
    Wait(6000)
    local list = lib.callback.await('survival-looting:server:activeDrops', false)
    for _, drop in pairs(list or {}) do register(drop) end

    while true do
        Wait(2000)
        local pc = GetEntityCoords(PlayerPedId())
        for id, a in pairs(active) do
            local d = #(pc - a.drop.coords)
            if d < SPAWN_DIST and not a.obj then
                spawnCrate(id, a)
            elseif d > SPAWN_DIST + 80.0 and a.obj then
                if a.fx then StopParticleFxLooped(a.fx, false) a.fx = nil end
                exports['qb-target']:RemoveTargetEntity(a.obj)
                DeleteEntity(a.obj)
                a.obj = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(active) do cleanup(id) end
end)
