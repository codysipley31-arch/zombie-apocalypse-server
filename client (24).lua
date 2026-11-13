local function poolOk()
    return #GetGamePool('CPed') < Config.PedPoolSoftLimit
end

local function groundAt(x, y, refZ)
    RequestCollisionAtCoord(x, y, refZ)
    local found, z = GetGroundZFor_3dCoord(x, y, refZ + 40.0, false)
    if found then return z end
    return nil
end

-- Spawn `size` zombies in a loose cluster around `center`, optionally marching to `rally`.
local function spawnCluster(center, size, spread, rally)
    local made = 0
    for _ = 1, size do
        if not poolOk() then break end
        local a = math.random() * 2.0 * math.pi
        local d = math.random() * spread
        local x, y = center.x + math.cos(a) * d, center.y + math.sin(a) * d
        local z = groundAt(x, y, center.z)
        if z then
            local ped = exports['zombie-ai']:SpawnZombie(vec3(x, y, z), { rally = rally })
            if ped then made = made + 1 end
            Wait(60)
        end
    end
    return made
end

RegisterNetEvent('zombie-hordes:client:roaming', function(size)
    local me = PlayerPedId()
    local mc = GetEntityCoords(me)
    local d = Config.Roaming.spawnDist
    local angle = math.random() * 2.0 * math.pi
    local dist = d.min + math.random() * (d.max - d.min)
    local center = vec3(mc.x + math.cos(angle) * dist, mc.y + math.sin(angle) * dist, mc.z)

    if Config.Roaming.warning then
        lib.notify({
            title = 'Horde',
            description = 'A low moan carries through the air... something big is coming.',
            type = 'warning',
            duration = 8000,
        })
    end

    spawnCluster(center, size, 14.0, mc)
end)

-- Static nests: ask the server (global cooldown), spawn the horde if approved.
CreateThread(function()
    Wait(5000)
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for i, nest in ipairs(Config.Nests) do
            if #(pc - nest.coords) < Config.NestTriggerDistance then
                if lib.callback.await('zombie-hordes:server:claimNest', false, i) then
                    CreateThread(function()
                        spawnCluster(nest.coords, nest.size, nest.radius, nil)
                    end)
                end
            end
        end
    end
end)
