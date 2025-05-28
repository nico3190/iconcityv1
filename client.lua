ESX = exports["es_extended"]:getSharedObject()

local isLockpicking = false

local function GetClosestDoor(coords)
    local closestDoor = exports["doors_creator"]:getClosestActiveDoor()
    
    if closestDoor then
        print("DEBUG: Closest door found:", json.encode(closestDoor))
        
        local doorCoords = nil
        local doorEntity = nil
        
        if closestDoor.coords then
            doorCoords = vector3(closestDoor.coords.x, closestDoor.coords.y, closestDoor.coords.z)
        elseif closestDoor.position then
            doorCoords = vector3(closestDoor.position.x, closestDoor.position.y, closestDoor.position.z)
        elseif closestDoor.object then
            doorEntity = closestDoor.object
            doorCoords = GetEntityCoords(doorEntity)
            print("DEBUG: Using entity coords:", doorCoords)
        end
        
        if doorCoords then
            local distance = #(coords - doorCoords)
            print("DEBUG: Door distance:", distance, "Max distance:", Config.MaxDistance)
            
            if distance <= Config.MaxDistance then
                return {
                    id = closestDoor.id or closestDoor.doorId,
                    coords = doorCoords,
                    distance = distance,
                    state = closestDoor.state or closestDoor.locked,
                    entity = doorEntity or closestDoor.entity,
                    label = closestDoor.label or ("Tür ID: " .. (closestDoor.id or "Unknown"))
                }
            else
                print("DEBUG: Door too far away:", distance, ">", Config.MaxDistance)
            end
        else
            print("DEBUG: Could not determine door coordinates")
        end
    else
        print("DEBUG: No door found by getClosestActiveDoor()")
    end
    
    return nil
end

local function GetTargetInfo(playerCoords)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.MaxDistance, 0, 71)
    local door = GetClosestDoor(playerCoords)
    
    local vehicleDistance = 999
    local doorDistance = 999
    
    if vehicle ~= 0 then
        local vehicleCoords = GetEntityCoords(vehicle)
        vehicleDistance = #(playerCoords - vehicleCoords)
        print("DEBUG: Vehicle found at distance:", vehicleDistance)
    end
    
    if door then
        doorDistance = door.distance
        print("DEBUG: Door found at distance:", doorDistance, "State:", door.state, "Label:", door.label)
    end
    
    if vehicleDistance < doorDistance and vehicle ~= 0 and vehicleDistance <= Config.MaxDistance then
        return {
            type = "vehicle",
            entity = vehicle,
            distance = vehicleDistance,
            coords = GetEntityCoords(vehicle)
        }
    elseif door and doorDistance <= Config.MaxDistance then
        return {
            type = "door",
            entity = door.entity,
            doorId = door.id,
            distance = doorDistance,
            coords = door.coords,
            state = door.state,
            label = door.label
        }
    end
    
    print("DEBUG: No valid target found - Vehicle distance:", vehicleDistance, "Door distance:", doorDistance, "Max distance:", Config.MaxDistance)
    return nil
end

RegisterNetEvent('nico_dietrich:useLockpick')
AddEventHandler('nico_dietrich:useLockpick', function()
    if isLockpicking then
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local target = GetTargetInfo(playerCoords)

    if not target then
        Config.NotifyTrigger('error', Config.Locales['no_target'])
        return
    end

    if target.distance > Config.MaxDistance then
        Config.NotifyTrigger('error', Config.Locales['too_far'])
        return
    end

    local isLocked = false
    local lockpickTime = 0
    local lockpickChance = 0
    local targetInfo = ""
    
    if target.type == "vehicle" then
        local lockStatus = GetVehicleDoorLockStatus(target.entity)
        isLocked = lockStatus ~= 1 and lockStatus ~= 0
        lockpickTime = Config.VehicleLockpickTime
        lockpickChance = Config.VehicleLockpickChance
        targetInfo = GetDisplayNameFromVehicleModel(GetEntityModel(target.entity))
        
        if not isLocked then
            Config.NotifyTrigger('error', Config.Locales['vehicle_not_locked'])
            return
        end
    elseif target.type == "door" then
        print("DEBUG: Door state check - State:", target.state, "Type:", type(target.state))
        
        isLocked = target.state == 1 or target.state == true or target.state == "locked" or target.state == nil
        lockpickTime = Config.DoorLockpickTime
        lockpickChance = Config.DoorLockpickChance
        targetInfo = target.label or ("Tür (ID: " .. target.doorId .. ")")
        
        if not isLocked then
            Config.NotifyTrigger('error', Config.Locales['door_not_locked'])
            return
        end
    end

    print("DEBUG: Starting lockpick on", target.type, "- Locked:", isLocked)

    isLockpicking = true
    
    if target.entity then
        TaskTurnPedToFaceEntity(playerPed, target.entity, 1000)
    else
        TaskTurnPedToFaceCoord(playerPed, target.coords.x, target.coords.y, target.coords.z, 1000)
    end
    Wait(1000)
    
    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, "machinic_loop_mechandplayer", 8.0, -8.0, -1, 16, 0, false, false, false)
    
    local progressMsg = target.type == "vehicle" and Config.Locales['lockpicking_vehicle'] or Config.Locales['lockpicking_door']
    Config.progress_bar(progressMsg, lockpickTime)
    
    Wait(lockpickTime)
    
    ClearPedTasks(playerPed)
    isLockpicking = false
    
    local success = math.random(1, 100) <= lockpickChance
    
    local logCoords = {
        x = math.floor(playerCoords.x * 1000) / 1000,
        y = math.floor(playerCoords.y * 1000) / 1000,
        z = math.floor(playerCoords.z * 1000) / 1000
    }
    
    TriggerServerEvent('nico_dietrich:sendLog', target.type, targetInfo, logCoords, success)
    
    if success then
        if target.type == "vehicle" then
            SetVehicleDoorsLocked(target.entity, 1)
            SetVehicleDoorsLockedForAllPlayers(target.entity, false)
            Config.NotifyTrigger('success', Config.Locales['vehicle_lockpick_success'])
        elseif target.type == "door" then
            TriggerServerEvent('nico_dietrich:unlockDoor', target.doorId)
            Config.NotifyTrigger('success', Config.Locales['door_lockpick_success'])
        end
    else
        local failMsg = target.type == "vehicle" and Config.Locales['vehicle_lockpick_failed'] or Config.Locales['door_lockpick_failed']
        Config.NotifyTrigger('error', failMsg)
        TriggerServerEvent('nico_dietrich:removeLockpick')
    end
end)

RegisterCommand('debugdoors', function()
    local closestDoor = exports["doors_creator"]:getClosestActiveDoor()
    print("=== DEBUG: Closest door ===")
    if closestDoor then
        print("Door data:", json.encode(closestDoor))
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local doorCoords = nil
        
        if closestDoor.coords then
            doorCoords = vector3(closestDoor.coords.x, closestDoor.coords.y, closestDoor.coords.z)
        elseif closestDoor.position then
            doorCoords = vector3(closestDoor.position.x, closestDoor.position.y, closestDoor.position.z)
        elseif closestDoor.object then
            doorCoords = GetEntityCoords(closestDoor.object)
            print("Entity coords:", doorCoords)
        end
        
        if doorCoords then
            local distance = #(playerCoords - doorCoords)
            print("Distance to door:", distance)
            print("Max distance:", Config.MaxDistance)
            print("In range:", distance <= Config.MaxDistance)
        end
        
        if closestDoor.id then
            TriggerServerEvent('nico_dietrich:getDoorData', closestDoor.id)
        end
    else
        print("No closest door found")
    end
end)

RegisterNetEvent('nico_dietrich:receiveDoorData')
AddEventHandler('nico_dietrich:receiveDoorData', function(doorData)
    print("=== DEBUG: Door data from server ===")
    if doorData then
        print("Server door data:", json.encode(doorData))
    else
        print("No door data received from server")
    end
end)