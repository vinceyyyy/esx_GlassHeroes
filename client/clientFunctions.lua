local pedHash = Config.Peds[1].pedModel

function createPed()
    local pedVector3 = Config.Peds[1].pedCoords
    local pedHeading = Config.Peds[1].pedHeading
    
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(50)
    end

    local ped = CreatePed(4, pedHash, pedVector3, pedHeading, false, false)
    TriggerEvent('esx_GlasshHeroes:updatePedStateBag', ped)

    FreezeEntityPosition(ped, true)
    addClientPedProperties(ped)

    return ped
end

function addClientPedProperties(ped)
    if DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanBeTargetted(ped, false)
        SetPedCanRagdoll(ped, false)
        SetRagdollBlockingFlags(ped, 1)
        SetPedSuffersCriticalHits(ped, false)
        SetPedCombatMovement(ped, 0)
        SetPedCanEvasiveDive(ped, false)
        SetPedConfigFlag(ped, 208, true)
        SetPedConfigFlag(ped, 39, true)
    else
        error("Error adding properties to ped: ped has no handle")
    end

end

function removePedProperties(ped)
    FreezeEntityPosition(ped, false)
end

function openDialogMenu()
    local vehicles, distances = fetchNearbyVehicles(GetEntityCoords(PlayerPedId()), Config.Other[3].fetchVehiclesRadius)
    local options = {}

    for i, vehicle in ipairs(vehicles) do
        local model = GetEntityModel(vehicle)
        local fullName = GetLabelText(GetDisplayNameFromVehicleModel(model))
        local distance = math.ceil(distances[i])
        local licensePlate = GetVehicleNumberPlateText(vehicle)

        local vehicleData = {
            vehicle = vehicle,
            model = model,
            licensePlate = licensePlate,
            fullName = fullName,
            distance = distance
        }

        table.insert(options, {
            title = string.format('%s (%s meters) ', fullName, distance),
            description = 'License plate: ' .. licensePlate,
            icon = 'car',
            event = 'mechanic:payMenu',
            args = vehicleData
            
        })
        
    end

    lib.registerContext({
        id = 'mechanic_menu',
        title = 'Nearby vehicles',
        options = options

    })

    lib.showContext('mechanic_menu')
end

function fetchNearbyVehicles(coords, radius)
    local vehicles = {}
    local distances = {}
    local handle, vehicle = FindFirstVehicle()
    local success

    repeat
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = Vdist(coords, vehicleCoords)
        local vehicleModel = GetEntityModel(vehicle)

        if distance <= radius then
            if IsThisModelACar(vehicleModel) 
            or IsThisModelAQuadbike(vehicleModel)
            or GetVehicleClass(vehicle) == 8 then
                table.insert(vehicles, vehicle)
                table.insert(distances, distance)
            end
            
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)

    return vehicles, distances
end

function determineVehicleDamage(vehicle)
    local model = GetEntityModel(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local petrolTankHealth = GetVehiclePetrolTankHealth(vehicle)
    local isVehicleBumperBrokenOffFront = IsVehicleBumperBrokenOff(vehicle, true)
    local isVehicleBumperBrokenOffRear = IsVehicleBumperBrokenOff(vehicle, false)

    local healthPercentage = tonumber(string.format("%.2f", ((engineHealth + bodyHealth + petrolTankHealth)/3)/10))

    local numberDoorsMissing = 0
    local numberTyresBurst = 0

    if IsThisModelACar(model) then
        for i = 0, 5 do
            if IsVehicleDoorDamaged(vehicle, i) then
                numberDoorsMissing = numberDoorsMissing + 1
            end

            if IsVehicleTyreBurst(vehicle, i, false) then
                numberTyresBurst = numberTyresBurst + 1
            end

        end
        
    else
        for i = 0, 5 do
            if IsVehicleTyreBurst(vehicle, i, false) then
                numberTyresBurst = numberTyresBurst + 1
            end
        end
    end
    
    local repairCost, onlyHealthCost = calculateRepairCost(
    healthPercentage, 
    numberDoorsMissing, 
    numberTyresBurst, 
    isVehicleBumperBrokenOffFront, 
    isVehicleBumperBrokenOffRear)

    if healthPercentage < 0.0 and healthPercentage > -160.0 then
        healthPercentage = 'Critical'
    elseif healthPercentage <= -160.0 then
        healthPercentage = 'Completely destroyed'
    else
        healthPercentage = healthPercentage .. '%'
    end

    return healthPercentage, numberDoorsMissing, numberTyresBurst, repairCost, onlyHealthCost
end

function calculateRepairCost(healthPercentage, numberDoorsMissing, numberTyresBurst, isVehicleBumperBrokenOffFront, isVehicleBumperBrokenOffRear)
    local repairCost = 0 
    local costFactor = Config.CarCosts[1].costFactor
    local bumperCost = Config.CarCosts[2].bumperCost
    local doorCost = Config.CarCosts[3].doorCost
    local tyreCost = Config.CarCosts[4].tyreCost

    if healthPercentage >= -160.0 then
        local damagePercentage = 100 - healthPercentage

        repairCost = (damagePercentage / 100) * costFactor + (numberDoorsMissing * doorCost) + (numberTyresBurst * tyreCost)
    end

    if isVehicleBumperBrokenOffFront then
        repairCost = repairCost + bumperCost
    end

    if isVehicleBumperBrokenOffRear then
        repairCost = repairCost + bumperCost
    end

    local onlyHealthCost = repairCost - numberTyresBurst*tyreCost - numberDoorsMissing*doorCost
    if onlyHealthCost < 0 then
        onlyHealthCost = 'N/A'
        return repairCost, onlyHealthCost
    end

    currentRepairCost = tonumber(string.format("%.2f", repairCost))

    return tonumber(string.format("%.2f", repairCost)), onlyHealthCost
end

function showProceedAlert(vehicleName, repairPrice)
    local alert = lib.alertDialog({
        header = 'Confirmation',
        content = 'Are you sure you want to repair the ' .. vehicleName .. ' for ' .. repairPrice .. '$?',
        centered = true,
        cancel = true,
        size = 'lg'
    })

    return alert
end

function pedGoToCar(targetVehicle, ped)
    removePedProperties(ped)
    TaskGoToEntity(ped, targetVehicle, -1, 0.25, 1.0, 1073741824, 0)
    return true
end

function pedRepairVehicle(targetVeh, ped)
    local animDict = 'mini@repair'
    local animName = 'fixing_a_ped'
    local repairTime = determineRepairTime()
    RequestAnimDict(animDict)

    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    addClientPedProperties(ped)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, repairTime, 1, 0, false, false, false)

    if lib.progressCircle({
        duration = repairTime,
        label = 'Repairing car',
        position = 'bottom',
        canCancel = false
    }) then 
        fixVehicle(targetVeh) 
        SetVehicleDoorsLocked(targetVeh, 0)
    
    end

    ClearPedTasks(ped)
    TriggerEvent('esx_GlassHeroes:NPCfinishedWork', 'isNPCworking', false)
    goBackToCoords(ped)
    
end

function fixVehicle(vehicle)
    SetVehicleBodyHealth(vehicle, 1000)
    SetVehicleEngineHealth(vehicle, 1000)
    SetVehiclePetrolTankHealth(vehicle, 1000)

    for i = 0, 7 do
        SetVehicleTyreFixed(vehicle, i)
    end

    SetVehicleFixed(vehicle)
end

function goBackToCoords(ped)
    TaskGoToCoordAnyMeans(ped, Config.Peds[1].pedCoords, 1.0, 0, false, 0, 0)
    removePedProperties(ped)
    TriggerEvent('esx_GlassHeroes:NPCfinishedWork', 'hasFinishedWork', true)
end

function determineRepairTime()
    local maxRepairCost = Config.RepairTime[1].maxRepairCost
    local maxRepairTime = Config.RepairTime[2].maxRepairTime 
    local minRepairTime = Config.RepairTime[3].minRepairTime
    local addedTime = Config.RepairTime[4].addedTime

    local repairTime = ((currentRepairCost / maxRepairCost) * (maxRepairTime - minRepairTime)) + addedTime

    return math.floor(repairTime)
end