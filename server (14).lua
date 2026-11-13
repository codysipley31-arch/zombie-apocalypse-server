local QBCore = exports['qb-core']:GetCoreObject()

local busy = {}     -- [src] = true while a login/creation is in progress

local function randomCamp()
    local zones = exports['zombie-ai']:GetSafeZones()
    if not zones or #zones == 0 then return Config.Fallback end
    local z = zones[math.random(#zones)]
    local a, r = math.random() * math.pi * 2, math.random() * 6.0
    return vec4(z.coords.x + math.cos(a) * r, z.coords.y + math.sin(a) * r, z.coords.z, math.random(0, 359) + 0.0)
end

local function validName(s)
    if type(s) ~= 'string' then return false end
    s = s:gsub('^%s+', ''):gsub('%s+$', '')
    if #s < Config.NameMin or #s > Config.NameMax then return false end
    return s:match(Config.NamePattern) ~= nil
end

local function titleCase(s)
    s = s:gsub('^%s+', ''):gsub('%s+$', '')
    return (s:gsub("(%a)([%w_']*)", function(a, b) return a:upper() .. b:lower() end))
end

-- Step 1: client says it is ready. Log in an existing character or ask it to create one.
lib.callback.register('survival-start:server:enter', function(src)
    if busy[src] then return nil end
    busy[src] = true

    local license = QBCore.Functions.GetIdentifier(src, 'license')
    if not license then
        busy[src] = nil
        return { error = 'No Rockstar license found.' }
    end

    local row = MySQL.single.await('SELECT citizenid FROM players WHERE license = ? ORDER BY cid ASC LIMIT 1', { license })
    if not row then
        return { new = true }          -- stays `busy` until create finishes or the player leaves
    end

    local ok = QBCore.Player.Login(src, row.citizenid)
    busy[src] = nil
    if not ok then return { error = 'Could not load your character.' } end

    local Player = QBCore.Functions.GetPlayer(src)
    local spawn
    local pos = Player.PlayerData.position
    if Player.PlayerData.metadata.isdead or not pos or not pos.x or (pos.x == 0 and pos.y == 0) then
        Player.Functions.SetMetaData('isdead', false)
        spawn = randomCamp()
    else
        spawn = vec4(pos.x, pos.y, pos.z + 0.5, 0.0)
    end
    return { spawn = spawn, model = nil }
end)

-- Step 2 (first join only): create the character.
lib.callback.register('survival-start:server:create', function(src, data)
    if not busy[src] then return nil end
    if type(data) ~= 'table' or not validName(data.firstname) or not validName(data.lastname) then
        return { error = ('Names must be %d-%d letters.'):format(Config.NameMin, Config.NameMax) }
    end
    local gender = data.gender == 1 and 1 or 0

    local newData = {
        cid = 1,
        charinfo = {
            firstname = titleCase(data.firstname),
            lastname = titleCase(data.lastname),
            birthdate = '1990-01-01',
            gender = gender,
            nationality = 'American',
        },
    }
    local ok = QBCore.Player.Login(src, false, newData)
    busy[src] = nil
    if not ok then return { error = 'Could not create your character.' } end

    -- starter kit (inventory is set up by ox_inventory on the PlayerLoaded event)
    SetTimeout(5000, function()
        for _, it in ipairs(Config.StarterItems) do
            exports.ox_inventory:AddItem(src, it[1], it[2])
        end
    end)

    return { spawn = randomCamp(), model = Config.Models[gender] }
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
