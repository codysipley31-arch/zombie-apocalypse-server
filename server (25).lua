local nestReady = {}        -- [index] = os.time() after which the nest may spawn again

local function nightFactor()
    local m = GlobalState.worldMinutes
    if not m then return 0.0 end
    local h = m / 60.0
    -- same shape as zombie-ai: full dark 21:00-04:30 with 2h ramps
    if h >= 21.0 or h < 4.5 then return 1.0 end
    if h >= 19.0 then return (h - 19.0) / 2.0 end
    if h < 6.5 then return 1.0 - (h - 4.5) / 2.0 end
    return 0.0
end

local function pickSurvivor()
    local candidates = {}
    for _, id in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(id)
        if ped ~= 0 and GetEntityHealth(ped) > 0 then
            local c = GetEntityCoords(ped)
            local safe = false
            for _, z in ipairs(exports['zombie-ai']:GetSafeZones()) do
                if #(c - z.coords) <= z.radius + 40.0 then safe = true break end
            end
            if not safe then candidates[#candidates + 1] = tonumber(id) end
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(#candidates)]
end

CreateThread(function()
    if not Config.Roaming.enabled then return end
    local r = Config.Roaming
    while true do
        local wait = math.random(r.minMinutes, r.maxMinutes) * 60 * 1000
        wait = math.floor(wait * (1.0 - (1.0 - r.nightMult) * nightFactor()))
        Wait(wait)

        if #GetPlayers() >= r.minPlayers then
            local target = pickSurvivor()
            if target then
                local nf = nightFactor()
                local size = math.random(r.size.min, r.size.max) + math.floor(r.nightExtra * nf)
                TriggerClientEvent('zombie-hordes:client:roaming', target, size)
            end
        end
    end
end)

-- A client close to a nest asks whether it may spawn that nest's horde.
lib.callback.register('zombie-hordes:server:claimNest', function(src, index)
    local nest = Config.Nests[index]
    if not nest then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - nest.coords) > Config.NestTriggerDistance + 40.0 then return false end
    local now = os.time()
    if nestReady[index] and now < nestReady[index] then return false end
    nestReady[index] = now + nest.cooldown * 60
    return true
end)

lib.callback.register('zombie-hordes:server:nestList', function()
    return Config.Nests
end)
