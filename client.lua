local placing = false

local function help(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function raycastFromCamera(dist)
    local camPos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vec3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
    local dest = camPos + dir * dist
    local ray = StartShapeTestLosProbe(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, 1 + 16, PlayerPedId(), 0)
    local _, hit, coords = GetShapeTestResult(ray)
    return hit == 1, coords, dest
end

RegisterNetEvent('survival-basebuilding:client:startPlace', function(itemName)
    if placing then return end
    local def = Config.Pieces[itemName]
    if not def then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        lib.notify({ type = 'error', description = 'Get out of the vehicle first.' })
        return
    end

    local model = joaat(def.model)
    if not lib.requestModel(model, 5000) then return end

    placing = true
    local ghost = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    SetEntityCompletelyDisableCollision(ghost, true, false)
    FreezeEntityPosition(ghost, true)

    local heading = GetEntityHeading(PlayerPedId())
    local coords = nil

    while placing do
        Wait(0)
        local hit, hc, dest = raycastFromCamera(Config.MaxPlaceDistance)
        if hit then
            coords = hc
        else
            local found, gz = GetGroundZFor_3dCoord(dest.x, dest.y, dest.z + 2.0, false)
            coords = found and vec3(dest.x, dest.y, gz) or dest
        end
        coords = vec3(coords.x, coords.y, coords.z + def.z)

        SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(ghost, heading)
        PlaceObjectOnGroundProperly(ghost)

        help('~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ rotate   ~INPUT_CELLPHONE_LEFT~ / ~INPUT_CELLPHONE_RIGHT~ fine rotate\n~INPUT_PICKUP~ place   ~INPUT_FRONTEND_RRIGHT~ cancel')

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)

        if IsControlPressed(0, 172) then heading = heading + 1.8 end   -- arrow up
        if IsControlPressed(0, 173) then heading = heading - 1.8 end   -- arrow down
        if IsControlPressed(0, 174) then heading = heading + 0.4 end
        if IsControlPressed(0, 175) then heading = heading - 0.4 end

        if IsControlJustReleased(0, 177) or IsEntityDead(PlayerPedId()) then   -- backspace/cancel
            placing = false
            coords = nil
        elseif IsControlJustReleased(0, 38) then                              -- E
            local final = GetEntityCoords(ghost)
            local fh = GetEntityHeading(ghost)
            placing = false
            local ok, msg = lib.callback.await('survival-basebuilding:server:place', false, itemName, final, fh)
            if ok then
                lib.notify({ type = 'success', description = def.label .. ' placed.' })
            else
                lib.notify({ type = 'error', description = msg or 'Cannot place that here.' })
            end
        end
    end

    DeleteEntity(ghost)
    SetModelAsNoLongerNeeded(model)
end)

---------------------------------------------------------------------- interactions

local function netIdOf(entity)
    return NetworkGetNetworkIdFromEntity(entity)
end

local function isPiece(entity)
    return Entity(entity).state.basePiece ~= nil
end

CreateThread(function()
    local models, seen = {}, {}
    for _, def in pairs(Config.Pieces) do
        local h = joaat(def.model)
        if not seen[h] then seen[h] = true models[#models + 1] = h end
    end

    exports['qb-target']:AddTargetModel(models, {
        options = {
            {
                type = 'client', icon = 'fas fa-box-open', label = 'Open Crate',
                canInteract = function(entity)
                    return isPiece(entity) and Entity(entity).state.baseItem == 'base_crate'
                end,
                action = function(entity)
                    local stash = lib.callback.await('survival-basebuilding:server:openStash', false, netIdOf(entity))
                    if stash then
                        exports.ox_inventory:openInventory('stash', stash)
                    else
                        lib.notify({ type = 'error', description = 'It is locked up tight. Not yours.' })
                    end
                end,
            },
            {
                type = 'client', icon = 'fas fa-hand', label = 'Pick Up',
                canInteract = function(entity) return isPiece(entity) end,
                action = function(entity)
                    local ok, msg = lib.callback.await('survival-basebuilding:server:pickup', false, netIdOf(entity))
                    if ok then
                        lib.notify({ type = 'success', description = 'Picked up.' })
                    else
                        lib.notify({ type = 'error', description = msg or 'This is not yours to take.' })
                    end
                end,
            },
            {
                type = 'client', icon = 'fas fa-hammer', label = 'Break Down (crowbar)',
                canInteract = function(entity) return Config.AllowRaiding and isPiece(entity) end,
                action = function(entity)
                    local done = lib.progressCircle({
                        duration = Config.RaidTimeMs, label = 'Breaking it down...', position = 'bottom', canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 },
                    })
                    if not done then return end
                    local ok, msg = lib.callback.await('survival-basebuilding:server:raid', false, netIdOf(entity))
                    if ok then
                        lib.notify({ type = 'success', description = 'It splinters apart.' })
                    else
                        lib.notify({ type = 'error', description = msg or 'You cannot break that.' })
                    end
                end,
            },
        },
        distance = 2.5,
    })
end)
