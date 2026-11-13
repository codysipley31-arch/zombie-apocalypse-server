local recipes = {}
for _, r in ipairs(Config.Recipes) do recipes[r.id] = r end

local pending = {}      -- [src] = { id, startedAt }

local function nearBench(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pc = GetEntityCoords(ped)

    for _, b in ipairs(Config.FixedBenches) do
        if #(pc - vec3(b.x, b.y, b.z)) <= Config.BenchRange then return true end
    end

    local ok, res = pcall(function() return exports['survival-basebuilding']:IsNearWorkbench(src, Config.BenchRange) end)
    return ok and res or false
end

lib.callback.register('survival-crafting:server:begin', function(src, id, benchHere)
    local r = recipes[id]
    if not r then return false, 'Unknown recipe.' end
    if r.bench == 'workbench' and not nearBench(src) then return false, 'You need to be at a workbench.' end

    for item, count in pairs(r.ingredients) do
        if exports.ox_inventory:GetItemCount(src, item) < count then
            return false, 'You are missing ingredients.'
        end
    end
    pending[src] = { id = id, startedAt = os.clock() }
    return true
end)

lib.callback.register('survival-crafting:server:finish', function(src, id)
    local p = pending[src]
    pending[src] = nil
    local r = recipes[id]
    if not r or not p or p.id ~= id then return false, 'Crafting was interrupted.' end

    -- must have waited (at least most of) the crafting time
    if (os.clock() - p.startedAt) * 1000 < r.time * 0.85 then return false, 'Too fast.' end
    if r.bench == 'workbench' and not nearBench(src) then return false, 'You moved away from the workbench.' end

    for item, count in pairs(r.ingredients) do
        if exports.ox_inventory:GetItemCount(src, item) < count then return false, 'You are missing ingredients.' end
    end
    if not exports.ox_inventory:CanCarryItem(src, r.result[1], r.result[2]) then
        return false, 'You cannot carry that.'
    end

    for item, count in pairs(r.ingredients) do
        exports.ox_inventory:RemoveItem(src, item, count)
    end
    exports.ox_inventory:AddItem(src, r.result[1], r.result[2])
    return true
end)

lib.callback.register('survival-crafting:server:cancel', function(src)
    pending[src] = nil
    return true
end)

AddEventHandler('playerDropped', function() pending[source] = nil end)

---------------------------------------------------------------------- weapon repair

-- Hold the weapon to repair, then use the kit.
exports('weapon_repair_kit', function(event, item, inventory, slot)
    if event ~= 'usingItem' then return end
    local src = inventory.id
    local weapon = exports.ox_inventory:GetCurrentWeapon(src)
    if not weapon then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Hold the weapon you want to repair first.' })
        return false
    end
    local dur = (weapon.metadata and weapon.metadata.durability) or 100
    if dur >= 99 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = 'That weapon is in perfect shape.' })
        return false
    end
    exports.ox_inventory:SetDurability(src, weapon.slot, math.min(100, dur + Config.RepairAmount))
    exports.ox_inventory:RemoveItem(src, 'weapon_repair_kit', 1, nil, slot)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'You patch the weapon up as best you can.' })
    return false
end)
