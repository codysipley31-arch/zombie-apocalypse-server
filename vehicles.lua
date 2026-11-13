-- Abandoned vehicle scavenging and a simple fuel model.
-- Fuel is stored in the vehicle state bag `fuel` (0-100); the server validates changes.

local rummage = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 }

local function vehicleAction(action, label, time)
    return function(entity)
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local done = lib.progressCircle({
            duration = time,
            label = label,
            position = 'bottom',
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = rummage,
        })
        if not done then return end
        local res = lib.callback.await('survival-looting:server:vehicleAction', false, action, netId)

        if not res then
            lib.notify({ type = 'error', description = 'You cannot reach that.' })
        elseif res.searched then
            lib.notify({ type = 'inform', description = 'Already stripped bare.' })
        elseif res.missing then
            local needs = res.missing == 'WEAPON_CROWBAR' and 'a crowbar' or 'a fuel can'
            lib.notify({ type = 'error', description = ('You need %s.'):format(needs) })
        elseif res.dry then
            lib.notify({ type = 'inform', description = 'The tank is bone dry.' })
        elseif res.canFull then
            lib.notify({ type = 'error', description = 'Your fuel can has no room (or you have none).' })
        elseif res.siphoned then
            lib.notify({ type = 'success', description = ('Siphoned %.0f fuel.'):format(res.siphoned) })
        elseif res.empty then
            lib.notify({ type = 'inform', description = 'Nothing useful.' })
        elseif res.items then
            lib.notify({ title = 'Found', description = table.concat(res.items, ', '), type = 'success', duration = 6000 })
        end
    end
end

exports['qb-target']:AddGlobalVehicle({
    options = {
        {
            type = 'client', icon = 'fas fa-magnifying-glass', label = 'Search Vehicle',
            canInteract = function(entity) return not IsPedInAnyVehicle(PlayerPedId(), false) and GetVehicleEngineHealth(entity) > -1 end,
            action = vehicleAction('glovebox', 'Searching vehicle...', Config.Vehicle.glovebox.time),
        },
        {
            type = 'client', icon = 'fas fa-gears', label = 'Strip Parts (crowbar)',
            canInteract = function(entity) return not IsPedInAnyVehicle(PlayerPedId(), false) end,
            action = vehicleAction('strip', 'Stripping parts...', Config.Vehicle.strip.time),
        },
        {
            type = 'client', icon = 'fas fa-gas-pump', label = 'Siphon Fuel (fuel can)',
            canInteract = function(entity) return not IsPedInAnyVehicle(PlayerPedId(), false) end,
            action = vehicleAction('siphon', 'Siphoning fuel...', Config.Vehicle.siphon.time),
        },
    },
    distance = 2.5,
})

---------------------------------------------------------------------- refuelling with the fuel can

RegisterNetEvent('survival-looting:client:refuel', function(slot)
    local ped = PlayerPedId()
    local veh = lib.getClosestVehicle(GetEntityCoords(ped), 4.0, false)
    if not veh then
        lib.notify({ type = 'error', description = 'No vehicle close enough.' })
        return
    end
    local done = lib.progressCircle({
        duration = 6000, label = 'Refuelling...', position = 'bottom', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire', flag = 49 },
    })
    if not done then return end
    local res = lib.callback.await('survival-looting:server:refuel', false, NetworkGetNetworkIdFromEntity(veh), slot)
    if not res then
        lib.notify({ type = 'error', description = 'Something went wrong.' })
    elseif res.empty then
        lib.notify({ type = 'error', description = 'The can is empty.' })
    elseif res.full then
        lib.notify({ type = 'inform', description = 'The tank is already full.' })
    else
        lib.notify({ type = 'success', description = ('Added %.0f fuel.'):format(res.added) })
    end
end)

---------------------------------------------------------------------- fuel consumption

local function drawFuel(fuel)
    SetTextFont(4)
    SetTextScale(0.0, 0.3)
    SetTextOutline()
    local low = fuel < 15.0
    SetTextColour(low and 255 or 255, low and 90 or 255, low and 90 or 255, 230)
    SetTextEntry('STRING')
    AddTextComponentString(('FUEL %d%%'):format(math.floor(fuel + 0.5)))
    DrawText(0.185, 0.953)
end

CreateThread(function()
    if not Config.Fuel.enabled then return end
    local cfg = Config.Fuel
    local curVeh, tank, lastTick, lastSync = 0, nil, 0, 0
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetVehicleClass(veh) ~= 13 then
            if veh ~= curVeh then
                curVeh, tank = veh, nil
            end
            local netId = NetworkGetNetworkIdFromEntity(veh)

            if tank == nil then
                local f = Entity(veh).state.fuel
                if f == nil then
                    TriggerServerEvent('survival-looting:server:initFuel', netId)
                    Wait(400)
                else
                    tank, lastTick, lastSync = f + 0.0, GetGameTimer(), GetGameTimer()
                end
            else
                Wait(0)
                local now = GetGameTimer()
                if now - lastTick >= 1000 then
                    lastTick = now
                    if GetIsVehicleEngineRunning(veh) then
                        local burn = cfg.idle + cfg.consumption * (GetEntitySpeed(veh) / 30.0)
                        tank = math.max(0.0, tank - burn)
                    end
                    if tank <= 0.0 then
                        SetVehicleEngineOn(veh, false, true, true)
                        SetVehicleUndriveable(veh, true)
                    else
                        SetVehicleUndriveable(veh, false)
                    end
                end
                if now - lastSync >= 10000 then
                    lastSync = now
                    TriggerServerEvent('survival-looting:server:fuelUpdate', netId, tank)
                end
                drawFuel(tank)
            end
        else
            if curVeh ~= 0 and tank and DoesEntityExist(curVeh) then
                TriggerServerEvent('survival-looting:server:fuelUpdate', NetworkGetNetworkIdFromEntity(curVeh), tank)
            end
            curVeh, tank = 0, nil
            Wait(500)
        end
    end
end)
