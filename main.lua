local QBCore = exports['qb-core']:GetCoreObject()

local cooldowns = {}        -- [key] = os.time() when it can be searched again

---------------------------------------------------------------------- helpers

local function onCooldown(key)
    local t = cooldowns[key]
    return t and os.time() < t
end

local function setCooldown(key, minutes)
    cooldowns[key] = os.time() + minutes * 60
end

-- Periodic cleanup so the table never grows without bound
CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        local now = os.time()
        for k, t in pairs(cooldowns) do
            if now >= t then cooldowns[k] = nil end
        end
    end
end)

local function near(src, coords, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vec3(coords.x, coords.y, coords.z)) <= dist
end

local function roll(tableName)
    local def = Config.Tables[tableName]
    if not def then return {} end
    if math.random() < def.empty then return {} end

    local total = 0
    for _, e in ipairs(def.items) do total = total + e[4] end

    local out, merged = {}, {}
    local rolls = math.random(def.rolls[1], def.rolls[2])
    for _ = 1, rolls do
        local r = math.random() * total
        for _, e in ipairs(def.items) do
            r = r - e[4]
            if r <= 0 then
                merged[e[1]] = (merged[e[1]] or 0) + math.random(e[2], e[3])
                break
            end
        end
    end
    for name, count in pairs(merged) do out[#out + 1] = { name, count } end
    return out
end

-- Gives items; anything that does not fit is dropped at the player's feet.
local function give(src, items)
    local overflow, got = {}, {}
    for _, it in ipairs(items) do
        local name, count = it[1], it[2]
        if exports.ox_inventory:CanCarryItem(src, name, count) then
            exports.ox_inventory:AddItem(src, name, count)
            got[#got + 1] = ('%dx %s'):format(count, exports.ox_inventory:Items(name) and exports.ox_inventory:Items(name).label or name)
        else
            overflow[#overflow + 1] = { name, count }
        end
    end
    if #overflow > 0 then
        local c = GetEntityCoords(GetPlayerPed(src))
        exports.ox_inventory:CustomDrop('Loot', overflow, vec3(c.x, c.y, c.z - 0.9))
    end
    return got, #overflow > 0
end

local function result(src, items)
    if #items == 0 then return { empty = true } end
    local got, overflow = give(src, items)
    return { items = got, overflow = overflow }
end

---------------------------------------------------------------------- props

lib.callback.register('survival-looting:server:searchProp', function(src, cat, key, coords)
    local def = Config.Props[cat]
    if not def or type(key) ~= 'string' or type(coords) ~= 'vector3' then return nil end
    if not near(src, coords, 6.0) then return nil end
    local ck = 'prop:' .. key
    if onCooldown(ck) then return { searched = true } end
    setCooldown(ck, def.respawn)
    return result(src, roll(cat))
end)

lib.callback.register('survival-looting:server:checkProp', function(src, key)
    return onCooldown('prop:' .. key) and true or false
end)

---------------------------------------------------------------------- bunkers

lib.callback.register('survival-looting:server:searchBunker', function(src, b, c)
    local bunker = Config.Bunkers[b]
    local crate = bunker and bunker.crates[c]
    if not crate then return nil end
    if not near(src, crate.coords, 5.0) then return nil end
    local ck = ('bunker:%d:%d'):format(b, c)
    if onCooldown(ck) then return { searched = true } end
    setCooldown(ck, bunker.respawn)
    return result(src, roll(crate.table))
end)

lib.callback.register('survival-looting:server:bunkerState', function(src, b)
    local bunker = Config.Bunkers[b]
    if not bunker then return {} end
    local out = {}
    for c = 1, #bunker.crates do out[c] = onCooldown(('bunker:%d:%d'):format(b, c)) and true or false end
    return out
end)

---------------------------------------------------------------------- vehicles & fuel

local function vehicleFor(src, netId, dist)
    if type(netId) ~= 'number' then return nil end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(veh)) > (dist or 6.5) then return nil end
    return veh
end

local function initFuel(veh)
    local st = Entity(veh).state
    if st.fuel == nil then
        st:set('fuel', Config.Fuel.startFuelMin + math.random() * (Config.Fuel.startFuelMax - Config.Fuel.startFuelMin), true)
    end
    return st.fuel
end

RegisterNetEvent('survival-looting:server:initFuel', function(netId)
    local veh = vehicleFor(source, netId, 12.0)
    if veh then initFuel(veh) end
end)

-- The driver reports fuel burned. The server accepts only decreases from the real driver.
RegisterNetEvent('survival-looting:server:fuelUpdate', function(netId, value)
    local src = source
    local veh = vehicleFor(src, netId, 12.0)
    if not veh or type(value) ~= 'number' then return end
    if GetPedInVehicleSeat(veh, -1) ~= GetPlayerPed(src) then return end
    local cur = initFuel(veh)
    if value < cur and value >= math.max(0.0, cur - 6.0) then
        Entity(veh).state:set('fuel', value, true)
    end
end)

lib.callback.register('survival-looting:server:vehicleAction', function(src, action, netId)
    local def = Config.Vehicle[action]
    if not def then return nil end
    local veh = vehicleFor(src, netId)
    if not veh then return nil end

    local ck = ('veh:%s:%s'):format(NetworkGetNetworkIdFromEntity(veh), action)
    if onCooldown(ck) then return { searched = true } end

    if def.requires and exports.ox_inventory:GetItemCount(src, def.requires) < 1 then
        return { missing = def.requires }
    end

    if action == 'glovebox' then
        setCooldown(ck, def.cooldown)
        return result(src, roll('car'))
    elseif action == 'strip' then
        setCooldown(ck, def.cooldown)
        return result(src, roll('carparts'))
    elseif action == 'siphon' then
        local fuel = initFuel(veh)
        if fuel < def.minFuel then return { dry = true } end
        local cans = exports.ox_inventory:Search(src, 'slots', 'fuel_can')
        local canSlot
        for _, s in pairs(cans or {}) do
            local f = (s.metadata and s.metadata.fuel) or 0
            if f < Config.Vehicle.fuelCanCapacity - 0.5 then canSlot = s break end
        end
        if not canSlot then return { canFull = true } end
        local have = (canSlot.metadata and canSlot.metadata.fuel) or 0
        local take = math.min(def.takePerSiphon, Config.Vehicle.fuelCanCapacity - have, fuel)
        exports.ox_inventory:SetMetadata(src, canSlot.slot, { fuel = have + take, description = ('Fuel: %.0f / %.0f'):format(have + take, Config.Vehicle.fuelCanCapacity) })
        Entity(veh).state:set('fuel', fuel - take, true)
        setCooldown(ck, def.cooldown)
        return { siphoned = take }
    end
end)

lib.callback.register('survival-looting:server:refuel', function(src, netId, slot)
    local veh = vehicleFor(src, netId, 8.0)
    if not veh then return nil end
    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= 'fuel_can' then return nil end
    local have = (item.metadata and item.metadata.fuel) or 0
    if have <= 0 then return { empty = true } end
    local tank = initFuel(veh)
    if tank >= 99.0 then return { full = true } end
    local add = math.min(Config.Vehicle.refuelPerUse, have, 100.0 - tank)
    exports.ox_inventory:SetMetadata(src, slot, { fuel = have - add, description = ('Fuel: %.0f / %.0f'):format(have - add, Config.Vehicle.fuelCanCapacity) })
    Entity(veh).state:set('fuel', tank + add, true)
    return { added = add }
end)

-- ox_inventory item export: using the can asks the client to find a nearby vehicle
exports('fuel_can', function(event, item, inventory, slot)
    if event == 'usingItem' then
        TriggerClientEvent('survival-looting:client:refuel', inventory.id, slot)
        return false
    end
end)

---------------------------------------------------------------------- supply drops

local drops = {}            -- [id] = { id, coords, blip, expires }
local nextDropId = 0

local function endDrop(id)
    local d = drops[id]
    if not d then return end
    drops[id] = nil
    pcall(function() exports.ox_inventory:ClearInventory('airdrop_' .. id) end)
    TriggerClientEvent('survival-looting:client:airdropEnd', -1, id)
end

local function startDrop(coords)
    local A = Config.Airdrops
    nextDropId = nextDropId + 1
    local id = nextDropId
    coords = coords or A.locations[math.random(#A.locations)]

    local stashId = 'airdrop_' .. id
    exports.ox_inventory:RegisterStash(stashId, 'Supply Drop', 24, 120000, false)
    for _, it in ipairs(roll('airdrop')) do
        exports.ox_inventory:AddItem(stashId, it[1], it[2])
    end

    -- the radar blip is offset so players still have to hunt the last stretch
    local a, r = math.random() * math.pi * 2, math.random() * 80.0
    local blip = vec3(coords.x + math.cos(a) * r, coords.y + math.sin(a) * r, coords.z)

    drops[id] = { id = id, coords = coords, blip = blip, expires = os.time() + A.lifetimeMinutes * 60 }
    TriggerClientEvent('survival-looting:client:airdrop', -1, drops[id])

    SetTimeout(A.lifetimeMinutes * 60 * 1000, function() endDrop(id) end)

    if A.alertZombies then
        CreateThread(function()
            while drops[id] do
                exports['zombie-ai']:Alert(coords)
                Wait(60000)
            end
        end)
    end
    return id
end

CreateThread(function()
    local A = Config.Airdrops
    if not A.enabled then return end
    while true do
        Wait(math.random(A.minMinutes, A.maxMinutes) * 60 * 1000)
        if #GetPlayers() >= A.minPlayers then startDrop() end
    end
end)

lib.callback.register('survival-looting:server:activeDrops', function() return drops end)

lib.callback.register('survival-looting:server:openDrop', function(src, id)
    local d = drops[id]
    if not d or not near(src, d.coords, 8.0) then return false end
    return true
end)

lib.addCommand('airdrop', { help = 'Admin: call a supply drop at your position' }, function(src)
    if src ~= 0 and not QBCore.Functions.HasPermission(src, 'admin') then return end
    local c = GetEntityCoords(GetPlayerPed(src))
    startDrop(vec3(c.x + 4.0, c.y, c.z))
end)
