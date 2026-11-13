local hunger, thirst = Config.StartValue + 0.0, Config.StartValue + 0.0
local dead = false
local deadAt = 0
local warned = { hunger = false, thirst = false }

RegisterNetEvent('survival-needs:client:needs', function(h, t)
    hunger, thirst = h, t
    for key, v in pairs({ hunger = h, thirst = t }) do
        if v <= Config.Starving.warnAt and not warned[key] then
            warned[key] = true
            lib.notify({
                title = key == 'hunger' and 'Hungry' or 'Thirsty',
                description = key == 'hunger' and 'Your stomach is eating itself. Find food.' or 'Your mouth is dry. Find water.',
                type = 'warning',
            })
        elseif v > Config.Starving.warnAt + 10 then
            warned[key] = false
        end
    end
end)

---------------------------------------------------------------------- HUD

local function drawBar(x, y, w, h, frac, r, g, b)
    DrawRect(x + w / 2, y, w, h, 0, 0, 0, 150)
    local f = math.max(0.0, math.min(1.0, frac))
    DrawRect(x + (w * f) / 2, y, w * f, h * 0.7, r, g, b, 220)
end

local function drawLabel(text, x, y)
    SetTextFont(4)
    SetTextScale(0.0, 0.28)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

CreateThread(function()
    if not Config.HUD.enabled then return end
    while true do
        Wait(0)
        if not dead and not IsPauseMenuActive() then
            local x, y = Config.HUD.x, Config.HUD.y
            drawLabel('FOOD', x, y - 0.014)
            drawBar(x + 0.03, y, 0.06, 0.009, hunger / 100.0, 232, 163, 54)
            drawLabel('WATER', x, y + 0.012)
            drawBar(x + 0.03, y + 0.026, 0.06, 0.009, thirst / 100.0, 66, 165, 245)
        else
            Wait(250)
        end
    end
end)

---------------------------------------------------------------------- starvation / sprint sampling

CreateThread(function()
    while true do
        Wait(8000)
        local ped = PlayerPedId()
        if not dead and not IsEntityDead(ped) then
            local drain = 0
            if hunger <= 0.5 then drain = drain + Config.Starving.hungerDrain end
            if thirst <= 0.5 then drain = drain + Config.Starving.thirstDrain end
            if drain > 0 then
                SetEntityHealth(ped, math.max(1, GetEntityHealth(ped) - drain))
                ShakeGameplayCam('DRUNK_SHAKE', 0.2)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        local ped = PlayerPedId()
        if IsPedSprinting(ped) or IsPedSwimming(ped) then
            TriggerServerEvent('survival-needs:server:sprintSample')
        end
    end
end)

---------------------------------------------------------------------- healing

RegisterNetEvent('survival-needs:client:heal', function(amount, overSeconds, bleed)
    local ped = PlayerPedId()
    if bleed then ClearPedBloodDamage(ped) end
    if (overSeconds or 0) <= 0 then
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + amount))
        return
    end
    CreateThread(function()
        local ticks = overSeconds
        local per = amount / ticks
        for _ = 1, ticks do
            Wait(1000)
            local p = PlayerPedId()
            if IsEntityDead(p) then return end
            SetEntityHealth(p, math.min(GetEntityMaxHealth(p), math.floor(GetEntityHealth(p) + per + 0.5)))
        end
    end)
end)

---------------------------------------------------------------------- death & respawn

local function drawCenterText(text, y, scale)
    SetTextFont(4)
    SetTextScale(0.0, scale)
    SetTextColour(220, 220, 220, 255)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.5, y)
end

local function doRespawn()
    local spot = lib.callback.await('survival-needs:server:respawn', false)
    if not spot then return end
    DoScreenFadeOut(800)
    Wait(900)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(spot.x, spot.y, spot.z, spot.w, true, false)
    ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetEntityCoordsNoOffset(ped, spot.x, spot.y, spot.z, false, false, false)
    FreezeEntityPosition(ped, false)
    AnimpostfxStop('DeathFailOut')
    dead = false
    warned.hunger, warned.thirst = false, false
    Wait(500)
    DoScreenFadeIn(1200)
    lib.notify({ title = 'Back on your feet', description = 'You wake up at a survivor camp with nothing but scars.', type = 'inform', duration = 7000 })
end

RegisterNetEvent('survival-needs:client:revive', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    AnimpostfxStop('DeathFailOut')
    dead = false
end)

CreateThread(function()
    while true do
        Wait(300)
        local ped = PlayerPedId()
        if IsEntityDead(ped) and not dead then
            dead = true
            deadAt = GetGameTimer()
            TriggerServerEvent('survival-needs:server:died')
            AnimpostfxPlay('DeathFailOut', 0, true)

            CreateThread(function()
                while dead do
                    Wait(0)
                    local left = Config.Death.respawnSeconds - math.floor((GetGameTimer() - deadAt) / 1000)
                    drawCenterText('YOU DIED', 0.40, 1.2)
                    if left > 0 then
                        drawCenterText(('Respawn available in %d'):format(left), 0.50, 0.5)
                    else
                        drawCenterText('Press ~INPUT_PICKUP~ to respawn at a survivor camp', 0.50, 0.5)
                        if IsControlJustReleased(0, 38) then
                            doRespawn()
                        end
                    end
                end
            end)
        end
    end
end)
