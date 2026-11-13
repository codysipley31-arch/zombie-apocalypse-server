local stage = 0
local lastNotified = 0

local function clearEffects()
    AnimpostfxStop('DrugsMichaelAliensFight')
    AnimpostfxStop('DrugsDrivingIn')
    ResetPedMovementClipset(PlayerPedId(), 0.5)
end

RegisterNetEvent('zombie-infection:client:stage', function(newStage)
    local prev = stage
    stage = newStage
    if stage == 0 then
        clearEffects()
        return
    end
    if stage == 1 and prev == 0 then
        lib.notify({ title = 'Bitten', description = 'That bite broke the skin... keep an eye on it.', type = 'error', duration = 7000 })
    elseif stage == 2 then
        lib.notify({ title = 'Fever', description = 'You feel hot and shaky. You need antibiotics.', type = 'warning', duration = 7000 })
    elseif stage == 3 then
        lib.notify({ title = 'Delirium', description = 'The world swims. Time is almost out.', type = 'error', duration = 7000 })
        AnimpostfxPlay('DrugsMichaelAliensFight', 0, true)
        lib.requestAnimSet('move_m@drunk@verydrunk')
        SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 1.0)
    end
end)

-- Symptoms and drain
CreateThread(function()
    while true do
        Wait(8000)
        local ped = PlayerPedId()
        if stage >= 2 and not IsEntityDead(ped) then
            local drain = Config.Drain[stage] or 0
            if drain > 0 then
                SetEntityHealth(ped, math.max(1, GetEntityHealth(ped) - drain))
            end
            ShakeGameplayCam('DRUNK_SHAKE', stage == 3 and 0.8 or 0.25)
            if stage == 3 and math.random() < 0.3 then
                SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
            end
            if stage == 2 and math.random() < 0.4 then
                lib.notify({ description = '*cough cough*', type = 'inform', duration = 2500 })
            end
        end
    end
end)

-- The turn: die, lie still, rise as a zombie where you fell.
RegisterNetEvent('zombie-infection:client:turn', function()
    local ped = PlayerPedId()
    lib.notify({ title = 'Turned', description = 'Everything goes dark...', type = 'error', duration = 6000 })
    stage = 0
    clearEffects()
    local coords = GetEntityCoords(ped)
    SetEntityHealth(ped, 0)
    CreateThread(function()
        Wait(Config.ReanimateDelayMs)
        local ground = GetEntityCoords(ped)
        if ground == vec3(0.0, 0.0, 0.0) then ground = coords end
        exports['zombie-ai']:SpawnZombie(vec3(ground.x, ground.y, ground.z), { runner = Config.ReanimateAsRunner })
    end)
end)

-- Report death so a normal death does not carry the infection into the next life
CreateThread(function()
    local wasDead = false
    while true do
        Wait(1000)
        local dead = IsEntityDead(PlayerPedId())
        if dead and not wasDead then
            if stage > 0 then
                TriggerServerEvent('zombie-infection:server:died')
            end
            stage = 0
            clearEffects()
        end
        wasDead = dead
    end
end)
