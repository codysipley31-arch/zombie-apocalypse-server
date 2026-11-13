local function itemLabel(name)
    local data = exports.ox_inventory:Items(name)
    return data and data.label or name
end

local function ingredientText(r)
    local parts = {}
    for item, count in pairs(r.ingredients) do
        local have = exports.ox_inventory:Search('count', item) or 0
        parts[#parts + 1] = ('%s %d/%d'):format(itemLabel(item), math.min(have, count), count)
    end
    table.sort(parts)
    return table.concat(parts, '  |  ')
end

local function canCraft(r)
    for item, count in pairs(r.ingredients) do
        if (exports.ox_inventory:Search('count', item) or 0) < count then return false end
    end
    return true
end

local function craft(r)
    local ok, msg = lib.callback.await('survival-crafting:server:begin', false, r.id)
    if not ok then
        lib.notify({ type = 'error', description = msg or 'Cannot craft that.' })
        return
    end
    local done = lib.progressCircle({
        duration = r.time,
        label = ('Crafting %s...'):format(r.label),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    })
    if not done then
        lib.callback.await('survival-crafting:server:cancel', false)
        return
    end
    local ok2, msg2 = lib.callback.await('survival-crafting:server:finish', false, r.id)
    if ok2 then
        lib.notify({ type = 'success', description = ('Crafted %s.'):format(r.label) })
    else
        lib.notify({ type = 'error', description = msg2 or 'Crafting failed.' })
    end
end

local function openMenu(bench)
    local options = {}
    for _, r in ipairs(Config.Recipes) do
        if r.bench == 'hand' or r.bench == bench then
            options[#options + 1] = {
                title = r.label,
                description = ingredientText(r),
                icon = 'hammer',
                disabled = not canCraft(r),
                onSelect = function() craft(r) end,
            }
        end
    end
    local id = 'survival_craft_' .. bench
    lib.registerContext({
        id = id,
        title = bench == 'workbench' and 'Workbench' or 'Hand Crafting',
        options = options,
    })
    lib.showContext(id)
end

---------------------------------------------------------------------- hand crafting

RegisterCommand('survival_craft', function()
    if IsPedInAnyVehicle(PlayerPedId(), false) or IsEntityDead(PlayerPedId()) then return end
    openMenu('hand')
end, false)
RegisterKeyMapping('survival_craft', 'Hand crafting', 'keyboard', Config.HandCraftKey)
RegisterCommand('craft', function() ExecuteCommand('survival_craft') end, false)

---------------------------------------------------------------------- workbenches (placed + fixed)

CreateThread(function()
    exports['qb-target']:AddTargetModel({ joaat(Config.WorkbenchModel) }, {
        options = {
            {
                type = 'client',
                icon = 'fas fa-screwdriver-wrench',
                label = 'Use Workbench',
                action = function() openMenu('workbench') end,
            },
        },
        distance = 2.2,
    })
end)

local fixed = {}

CreateThread(function()
    Wait(3000)
    local model = joaat(Config.WorkbenchModel)
    while true do
        Wait(2500)
        local pc = GetEntityCoords(PlayerPedId())
        for i, b in ipairs(Config.FixedBenches) do
            local d = #(pc - vec3(b.x, b.y, b.z))
            if d < 70.0 and not fixed[i] then
                if lib.requestModel(model, 5000) then
                    local obj = CreateObject(model, b.x, b.y, b.z, false, false, false)
                    SetEntityHeading(obj, b.w)
                    PlaceObjectOnGroundProperly(obj)
                    FreezeEntityPosition(obj, true)
                    SetModelAsNoLongerNeeded(model)
                    fixed[i] = obj
                end
            elseif d > 110.0 and fixed[i] then
                DeleteEntity(fixed[i])
                fixed[i] = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, obj in pairs(fixed) do DeleteEntity(obj) end
end)
