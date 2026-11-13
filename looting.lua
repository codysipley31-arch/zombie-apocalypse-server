local localSearched = {}     -- [key] = GetGameTimer() until which we skip the target option

local rummage = { dict = 'amb@prop_human_bum_bin@base', clip = 'base', flag = 1 }

local function showResult(res)
    if not res then
        lib.notify({ type = 'error', description = 'You cannot reach that.' })
    elseif res.searched then
        lib.notify({ type = 'inform', description = 'Already picked clean.' })
    elseif res.missing then
        lib.notify({ type = 'error', description = 'You need a crowbar for that.' })
    elseif res.empty then
        lib.notify({ type = 'inform', description = 'Nothing useful here.' })
    elseif res.items then
        lib.notify({
            title = 'Found',
            description = table.concat(res.items, ', ') .. (res.overflow and '\n(some fell to the ground)' or ''),
            type = 'success',
            duration = 6000,
        })
    end
end

local function search(duration, label)
    return lib.progressCircle({
        duration = duration,
        label = label or 'Searching...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = rummage,
    })
end

local function propKey(entity)
    local c = GetEntityCoords(entity)
    return ('%d:%.0f:%.0f:%.0f'):format(GetEntityModel(entity), c.x, c.y, c.z)
end

---------------------------------------------------------------------- props (any world object by model)

CreateThread(function()
    for cat, def in pairs(Config.Props) do
        local models = {}
        for _, name in ipairs(def.models) do models[#models + 1] = joaat(name) end

        exports['qb-target']:AddTargetModel(models, {
            options = {
                {
                    type = 'client',
                    icon = def.icon,
                    label = def.label,
                    canInteract = function(entity)
                        local t = localSearched[propKey(entity)]
                        return not t or GetGameTimer() > t
                    end,
                    action = function(entity)
                        local key = propKey(entity)
                        local coords = GetEntityCoords(entity)
                        if not search(def.time) then return end
                        local res = lib.callback.await('survival-looting:server:searchProp', false, cat, key, coords)
                        if res and (res.searched or res.items or res.empty) then
                            localSearched[key] = GetGameTimer() + 5 * 60 * 1000
                        end
                        showResult(res)
                    end,
                },
            },
            distance = 2.0,
        })
    end
end)

---------------------------------------------------------------------- bunker crates

local crates = {}   -- [b..':'..c] = entity

local function spawnCrate(b, c, crate)
    local model = joaat(Config.BunkerModel)
    if not lib.requestModel(model, 5000) then return end
    local p = crate.coords
    local obj = CreateObject(model, p.x, p.y, p.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityHeading(obj, p.w)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type = 'client',
                icon = 'fas fa-box-open',
                label = 'Search Military Crate',
                action = function()
                    if not search(8000, 'Prying open the crate...') then return end
                    showResult(lib.callback.await('survival-looting:server:searchBunker', false, b, c))
                end,
            },
        },
        distance = 2.2,
    })
    crates[b .. ':' .. c] = obj
end

local function removeCrate(k)
    local obj = crates[k]
    if obj and DoesEntityExist(obj) then
        exports['qb-target']:RemoveTargetEntity(obj)
        DeleteEntity(obj)
    end
    crates[k] = nil
end

CreateThread(function()
    Wait(4000)
    while true do
        Wait(2000)
        local pc = GetEntityCoords(PlayerPedId())
        for b, bunker in ipairs(Config.Bunkers) do
            for c, crate in ipairs(bunker.crates) do
                local k = b .. ':' .. c
                local d = #(pc - vec3(crate.coords.x, crate.coords.y, crate.coords.z))
                if d < Config.BunkerSpawnDistance and not crates[k] then
                    spawnCrate(b, c, crate)
                elseif d > Config.BunkerSpawnDistance + 40.0 and crates[k] then
                    removeCrate(k)
                end
            end
        end
    end
end)

-- Blips for bunkers so players know where danger (and loot) is
CreateThread(function()
    for _, bunker in ipairs(Config.Bunkers) do
        local c = bunker.crates[1].coords
        local blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, 313)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Military Bunker: ' .. bunker.name)
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for k in pairs(crates) do removeCrate(k) end
end)
