local QBCore = exports['qb-core']:GetCoreObject()

local pieces = {}           -- [id] = { id, owner, item, coords, heading, entity, members = {citizenid=true} }
local byEntity = {}         -- [netId] = id

---------------------------------------------------------------------- spawning

local function spawnEntity(piece)
    local def = Config.Pieces[piece.item]
    if not def then return end
    local c = piece.coords
    local ent = CreateObjectNoOffset(joaat(def.model), c.x, c.y, c.z, true, true, false)
    local tries = 0
    while not DoesEntityExist(ent) and tries < 50 do Wait(20) tries = tries + 1 end
    if not DoesEntityExist(ent) then return end

    SetEntityHeading(ent, piece.heading)
    FreezeEntityPosition(ent, true)
    piece.entity = ent

    Wait(50)
    local netId = NetworkGetNetworkIdFromEntity(ent)
    Entity(ent).state:set('basePiece', piece.id, true)
    Entity(ent).state:set('baseItem', piece.item, true)
    byEntity[netId] = piece.id

    if def.stash then
        exports.ox_inventory:RegisterStash('base_' .. piece.id, def.label, def.stash.slots, def.stash.weight, false)
    end
end

local function removeEntity(piece)
    if piece.entity and DoesEntityExist(piece.entity) then
        byEntity[NetworkGetNetworkIdFromEntity(piece.entity)] = nil
        DeleteEntity(piece.entity)
    end
    piece.entity = nil
end

---------------------------------------------------------------------- database

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `survival_bases` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner` VARCHAR(50) NOT NULL,
            `item` VARCHAR(50) NOT NULL,
            `x` DOUBLE NOT NULL, `y` DOUBLE NOT NULL, `z` DOUBLE NOT NULL, `h` DOUBLE NOT NULL,
            `members` TEXT NULL,
            `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `owner` (`owner`)
        )
    ]])
    CreateThread(function()
        Wait(4000)
        local rows = MySQL.query.await('SELECT * FROM survival_bases')
        for _, r in ipairs(rows or {}) do
            local piece = {
                id = r.id, owner = r.owner, item = r.item,
                coords = vec3(r.x, r.y, r.z), heading = r.h,
                members = r.members and json.decode(r.members) or {},
            }
            pieces[r.id] = piece
            spawnEntity(piece)
        end
        print(('[survival-basebuilding] loaded %d base pieces'):format(#(rows or {})))
    end)
end)

-- Entities can vanish if the server restarts a routing bucket etc. Re-spawn any that disappeared.
CreateThread(function()
    Wait(30000)
    while true do
        Wait(60000)
        for _, piece in pairs(pieces) do
            if not piece.entity or not DoesEntityExist(piece.entity) then
                piece.entity = nil
                spawnEntity(piece)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, piece in pairs(pieces) do removeEntity(piece) end
end)

---------------------------------------------------------------------- helpers

local function citizenId(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.citizenid
end

local function countOwned(cid)
    local n = 0
    for _, p in pairs(pieces) do if p.owner == cid then n = n + 1 end end
    return n
end

local function hasAccess(piece, cid)
    return piece.owner == cid or piece.members[cid] == true
end

local function pieceFromNetId(netId)
    local id = byEntity[netId]
    return id and pieces[id]
end

---------------------------------------------------------------------- placing

-- ox_inventory export: using a placeable asks the client to start the placement preview.
exports('place', function(event, item, inventory)
    if event == 'usingItem' then
        TriggerClientEvent('survival-basebuilding:client:startPlace', inventory.id, item.name)
        return false
    end
end)

lib.callback.register('survival-basebuilding:server:place', function(src, itemName, coords, heading)
    local def = Config.Pieces[itemName]
    if not def or type(coords) ~= 'vector3' or type(heading) ~= 'number' then return false, 'Invalid piece.' end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - coords) > Config.MaxPlaceDistance + 3.0 then return false, 'Too far away.' end

    local cid = citizenId(src)
    if not cid then return false, 'Not loaded.' end
    if countOwned(cid) >= Config.MaxPiecesPerPlayer then return false, 'You have reached your build limit.' end
    if exports.ox_inventory:GetItemCount(src, itemName) < 1 then return false, 'You do not have that item.' end

    for _, z in ipairs(exports['zombie-ai']:GetSafeZones()) do
        if #(coords - z.coords) < z.radius + Config.MinDistanceFromSafeZone then
            return false, 'You cannot build this close to a safe zone.'
        end
    end
    for _, p in pairs(pieces) do
        if p.item == itemName and #(p.coords - coords) < Config.MinSpacing then
            return false, 'Something is already there.'
        end
    end

    if not exports.ox_inventory:RemoveItem(src, itemName, 1) then return false, 'You do not have that item.' end

    heading = heading % 360.0
    local id = MySQL.insert.await(
        'INSERT INTO survival_bases (owner, item, x, y, z, h, members) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { cid, itemName, coords.x, coords.y, coords.z, heading, '{}' })
    local piece = { id = id, owner = cid, item = itemName, coords = coords, heading = heading, members = {} }
    pieces[id] = piece
    spawnEntity(piece)
    return true
end)

---------------------------------------------------------------------- interacting

lib.callback.register('survival-basebuilding:server:canUse', function(src, netId)
    local piece = pieceFromNetId(netId)
    if not piece then return nil end
    local cid = citizenId(src)
    return { owner = piece.owner == cid, access = cid and hasAccess(piece, cid) or false }
end)

lib.callback.register('survival-basebuilding:server:openStash', function(src, netId)
    local piece = pieceFromNetId(netId)
    if not piece or not piece.entity then return false end
    if #(GetEntityCoords(GetPlayerPed(src)) - piece.coords) > 6.0 then return false end
    local cid = citizenId(src)
    if not cid or not hasAccess(piece, cid) then return false end
    return 'base_' .. piece.id
end)

lib.callback.register('survival-basebuilding:server:pickup', function(src, netId)
    local piece = pieceFromNetId(netId)
    if not piece then return false end
    if #(GetEntityCoords(GetPlayerPed(src)) - piece.coords) > 6.0 then return false end
    local cid = citizenId(src)
    if piece.owner ~= cid then return false end

    if Config.Pieces[piece.item].stash then
        local items = exports.ox_inventory:GetInventoryItems('base_' .. piece.id)
        if items and next(items) then return false, 'Empty the crate first.' end
    end
    if not exports.ox_inventory:CanCarryItem(src, piece.item, 1) then return false, 'You cannot carry that.' end

    exports.ox_inventory:AddItem(src, piece.item, 1)
    removeEntity(piece)
    pieces[piece.id] = nil
    MySQL.query('DELETE FROM survival_bases WHERE id = ?', { piece.id })
    return true
end)

-- Raiding: non-owners with a crowbar can break a piece. Stash contents spill to the ground.
lib.callback.register('survival-basebuilding:server:raid', function(src, netId)
    if not Config.AllowRaiding then return false end
    local piece = pieceFromNetId(netId)
    if not piece then return false end
    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - piece.coords) > 6.0 then return false end
    local cid = citizenId(src)
    if not cid or hasAccess(piece, cid) then return false end
    if exports.ox_inventory:GetItemCount(src, Config.RaidItem) < 1 then return false, 'You need a crowbar.' end

    if Config.Pieces[piece.item].stash then
        local drop = {}
        for _, slot in pairs(exports.ox_inventory:GetInventoryItems('base_' .. piece.id) or {}) do
            drop[#drop + 1] = { slot.name, slot.count, slot.metadata }
        end
        if #drop > 0 then
            exports.ox_inventory:CustomDrop('Raided Crate', drop, vec3(piece.coords.x, piece.coords.y, piece.coords.z))
        end
    end
    removeEntity(piece)
    pieces[piece.id] = nil
    MySQL.query('DELETE FROM survival_bases WHERE id = ?', { piece.id })
    return true
end)

---------------------------------------------------------------------- friends

local function updateMembers(owner, mutate)
    for _, p in pairs(pieces) do
        if p.owner == owner then
            mutate(p.members)
            MySQL.update('UPDATE survival_bases SET members = ? WHERE id = ?', { json.encode(p.members), p.id })
        end
    end
end

lib.addCommand('baseinvite', { help = 'Give a nearby survivor access to your base', params = { { name = 'id', type = 'playerId' } } },
    function(src, args)
        local cid, target = citizenId(src), citizenId(args.id)
        if not cid or not target then return end
        if countOwned(cid) == 0 then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You do not own any base pieces.' })
            return
        end
        updateMembers(cid, function(m) m[target] = true end)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Access granted.' })
        TriggerClientEvent('ox_lib:notify', args.id, { type = 'inform', description = 'You were given access to a survivor base.' })
    end)

lib.addCommand('baseremove', { help = 'Remove a survivor from your base', params = { { name = 'id', type = 'playerId' } } },
    function(src, args)
        local cid, target = citizenId(src), citizenId(args.id)
        if not cid or not target then return end
        updateMembers(cid, function(m) m[target] = nil end)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Access removed.' })
    end)

---------------------------------------------------------------------- used by survival-crafting

exports('IsNearWorkbench', function(src, range)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pc = GetEntityCoords(ped)
    for _, p in pairs(pieces) do
        if Config.Pieces[p.item].workbench and #(pc - p.coords) <= (range or 6.0) then return true end
    end
    return false
end)
