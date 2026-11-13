local started = false

local function groundZ(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    for h = 0, 400, 25 do
        local found, gz = GetGroundZFor_3dCoord(x, y, z + 200.0 - h, false)
        if found then return gz end
        Wait(10)
    end
    return z
end

local function spawnAt(spawn, model)
    local args = { x = spawn.x, y = spawn.y, z = spawn.z, heading = spawn.w, skipFade = true }
    if model then args.model = joaat(model) end
    exports.spawnmanager:spawnPlayer(args)

    local ped = PlayerPedId()
    local deadline = GetGameTimer() + 8000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do Wait(50) end
    local z = groundZ(spawn.x, spawn.y, spawn.z)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, z + 0.5, false, false, false)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
end

local function finish(alreadyLoaded)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(1500)
    if not alreadyLoaded then
        -- QBCore resources (inventory bridge, appearance, ours) wait for these two
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
    end
end

local function askCharacter()
    while true do
        local input = lib.inputDialog('Who are you?', {
            { type = 'input', label = 'First name', required = true, min = Config.NameMin, max = Config.NameMax },
            { type = 'input', label = 'Last name', required = true, min = Config.NameMin, max = Config.NameMax },
            { type = 'select', label = 'Gender', required = true, default = '0',
              options = { { value = '0', label = 'Male' }, { value = '1', label = 'Female' } } },
        }, { allowCancel = false })

        if input then
            local res = lib.callback.await('survival-start:server:create', false, {
                firstname = input[1], lastname = input[2], gender = tonumber(input[3]),
            })
            if res and res.spawn then return res end
            lib.notify({ type = 'error', description = res and res.error or 'Something went wrong.' })
        end
    end
end

local function customize()
    local finished = false
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
        finished = true
    end, {
        ped = false, headBlend = true, faceFeatures = true, headOverlays = true,
        components = true, props = true, tattoos = false,
    })
    while not finished do Wait(200) end
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(100) end
    if started then return end
    started = true

    exports.spawnmanager:setAutoSpawn(false)
    DoScreenFadeOut(0)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    local res
    repeat
        res = lib.callback.await('survival-start:server:enter', false)
        if not res then Wait(1000) end
    until res

    if res.error then
        lib.notify({ type = 'error', description = res.error })
        return
    end

    if res.new then
        -- Spawn somewhere neutral, then run character creation on a freemode ped.
        exports.spawnmanager:spawnPlayer({ x = -1042.0, y = -2745.0, z = 21.4, heading = 330.0, model = joaat('mp_m_freemode_01'), skipFade = true })
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        DoScreenFadeIn(800)
        res = askCharacter()
        DoScreenFadeOut(600)
        Wait(700)

        if res.model then
            lib.requestModel(joaat(res.model), 10000)
            SetPlayerModel(PlayerId(), joaat(res.model))
            SetModelAsNoLongerNeeded(joaat(res.model))
            SetPedDefaultComponentVariation(PlayerPedId())
        end
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        DoScreenFadeIn(600)
        customize()
        DoScreenFadeOut(600)
        Wait(700)
        spawnAt(res.spawn, nil)
        finish(true)
        lib.notify({
            title = 'Welcome, survivor',
            description = 'Find supplies, avoid the dead, and stay out of the dark. Press K to craft.',
            type = 'inform', duration = 12000,
        })
    else
        spawnAt(res.spawn, nil)
        finish()
    end
end)
