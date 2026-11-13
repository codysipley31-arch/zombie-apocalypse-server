local QBCore = exports['qb-core']:GetCoreObject()

-- Infection progress (seconds) lives in QBCore player metadata `zinfection`, so it
-- survives relogs. false/nil = healthy.

local function getProgress(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    local p = Player.PlayerData.metadata.zinfection
    if type(p) ~= 'number' then return nil end
    return p
end

local function setProgress(src, value)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData('zinfection', value or false)
end

local function stageFor(progress)
    if not progress then return 0 end
    local stage = 0
    for s, threshold in ipairs(Config.Stages) do
        if progress >= threshold then stage = s end
    end
    return stage
end

local function pushStage(src, stage)
    TriggerClientEvent('zombie-infection:client:stage', src, stage)
end

---------------------------------------------------------------------- infecting

AddEventHandler('zombie-ai:bitten', function(src)
    if getProgress(src) then return end          -- already infected
    if math.random() > Config.InfectionChance then return end
    setProgress(src, 0)
    pushStage(src, 1)
end)

---------------------------------------------------------------------- progression

CreateThread(function()
    while true do
        Wait(Config.TickSeconds * 1000)
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local progress = getProgress(src)
            if progress then
                local before = stageFor(progress)
                progress = progress + Config.TickSeconds
                setProgress(src, progress)
                local after = stageFor(progress)
                if after ~= before then
                    pushStage(src, after)
                    if after >= 4 then
                        setProgress(src, nil)
                        TriggerClientEvent('zombie-infection:client:turn', src)
                    end
                end
            end
        end
    end
end)

-- Resync client on login / respawn
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(4000, function() pushStage(src, stageFor(getProgress(src))) end)
end)

-- Death clears infection (a normal death is not a turning)
RegisterNetEvent('zombie-infection:server:died', function()
    local src = source
    if getProgress(src) then setProgress(src, nil) end
end)

---------------------------------------------------------------------- cures

local function tryCure(src, itemName)
    local def = Config.CureItems[itemName]
    local progress = getProgress(src)
    if not progress then
        TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = "You don't feel sick." })
        return false
    end
    local stage = stageFor(progress)
    if stage > def.maxStage then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = ('The infection is too far along for %s.'):format(def.label),
        })
        return false
    end
    setProgress(src, nil)
    pushStage(src, 0)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'The fever breaks. You are going to live.' })
    return true
end

-- ox_inventory server exports (item defs point at these; `consume = 1` removes on success)
exports('antibiotics', function(event, item, inventory)
    if event == 'usingItem' then
        if not tryCure(inventory.id, 'antibiotics') then return false end
    end
end)

exports('cure_serum', function(event, item, inventory)
    if event == 'usingItem' then
        if not tryCure(inventory.id, 'cure_serum') then return false end
    end
end)

-- Admin: /infect [id], /cure [id]
local function isAdmin(src)
    return src == 0 or QBCore.Functions.HasPermission(src, 'admin')
end

lib.addCommand('infect', { help = 'Admin: infect a player', params = { { name = 'id', type = 'playerId', optional = true } } },
    function(src, args)
        if not isAdmin(src) then return end
        local t = args.id or src
        setProgress(t, 0)
        pushStage(t, 1)
    end)

lib.addCommand('cure', { help = 'Admin: cure a player', params = { { name = 'id', type = 'playerId', optional = true } } },
    function(src, args)
        if not isAdmin(src) then return end
        local t = args.id or src
        setProgress(t, nil)
        pushStage(t, 0)
    end)

exports('GetStage', function(src) return stageFor(getProgress(src)) end)
