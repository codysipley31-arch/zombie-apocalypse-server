-- Empty-world settings, synced clock, weather, gunshot noise and safe zone blips.

-- Remove ambient peds and (most) traffic. Zombies are the only population.
CreateThread(function()
    local w = Config.World
    while true do
        Wait(0)
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        SetVehicleDensityMultiplierThisFrame(w.trafficDensity)
        SetRandomVehicleDensityMultiplierThisFrame(w.trafficDensity)
        SetParkedVehicleDensityMultiplierThisFrame(w.parkedDensity)
        SetGarbageTrucks(false)
        SetRandomBoats(false)
        SetCreateRandomCops(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetCreateRandomCopsOnScenarios(false)
    end
end)

CreateThread(function()
    for i = 1, 15 do EnableDispatchService(i, false) end
    SetMaxWantedLevel(0)
    while true do
        Wait(1000)
        if GetPlayerWantedLevel(PlayerId()) ~= 0 then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
    end
end)

-- Synced day/night clock (server owns GlobalState.worldMinutes)
CreateThread(function()
    if not Config.Time.enabled then return end
    SetMillisecondsPerGameMinute(Config.Time.msPerMinute)
    while true do
        local m = GlobalState.worldMinutes
        if m then
            NetworkOverrideClockTime(math.floor(m / 60) % 24, math.floor(m % 60), 0)
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        SetWeatherTypeNowPersist(Config.World.weather)
        SetWeatherTypePersist(Config.World.weather)
        SetWeatherTypeNow(Config.World.weather)
        SetOverrideWeather(Config.World.weather)
        Wait(15000)
    end
end)

-- Gunshots and explosions draw zombies (suppressed weapons are quiet)
CreateThread(function()
    local lastSent = 0
    while true do
        Wait(150)
        local ped = PlayerPedId()
        if IsPedShooting(ped) and not IsPedCurrentWeaponSilenced(ped) then
            local now = GetGameTimer()
            if now - lastSent > 2000 then
                lastSent = now
                TriggerServerEvent('zombie-ai:server:noise', GetEntityCoords(ped))
            end
        end
    end
end)

-- Blips for safe zones
CreateThread(function()
    for _, z in ipairs(Config.SafeZones) do
        local radius = AddBlipForRadius(z.coords.x, z.coords.y, z.coords.z, z.radius)
        SetBlipColour(radius, 2)
        SetBlipAlpha(radius, 70)
        local b = AddBlipForCoord(z.coords.x, z.coords.y, z.coords.z)
        SetBlipSprite(b, 357)
        SetBlipScale(b, 0.8)
        SetBlipColour(b, 2)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Safe Zone: ' .. z.name)
        EndTextCommandSetBlipName(b)
    end
end)

-- Admin helper: prints the coords you stand on, copyable from the F8 console
RegisterNetEvent('zombie-ai:client:printCoords', function()
    local c = GetEntityCoords(PlayerPedId())
    local text = ('vec3(%.1f, %.1f, %.1f)'):format(c.x, c.y, c.z)
    print(text)
    lib.setClipboard(text)
    lib.notify({ title = 'Coords copied', description = text, type = 'success' })
end)
