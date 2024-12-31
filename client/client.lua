-- Variables
local pedVector3 = Config.Peds[1].pedCoords
local spawnRadius = Config.Other[1].spawnRadius
local infoBarRadius = Config.Other[2].infoBarRadius

local isNPCworking = false
local hasFinishedWork = false
local continueLoop = true

local ped = nil
local createdPeds = nil
local targetVehicle = nil

-- Events
RegisterNetEvent('esx_GlassHeroes:openDialogMenu', function()
    if Config.Features[1].requireNoMechanics then
        local mechanicsOnline = lib.callback.await('esx_GlassHeroes:requestMechanicsOnline', source)

        if mechanicsOnline < Config.Features[1].amountOfMechanics then
            openDialogMenu()
        else
            ESX.ShowNotification(Config.Features[1].errorMessage, 'error', 3000)
        end
    else
        openDialogMenu()
    end

end)

RegisterNetEvent('esx_GlassHeroes:NPCfinishedWork', function(type, bool)
    if type == 'isNPCworking' then
        if bool == true then
            isNPCworking = true
        else
            isNPCworking = false
        end
    end

    if type == 'hasFinishedWork' then
        if bool == true then
           hasFinishedWork = true
        else
            hasFinishedWork = false
        end
    end
end)

-- Event for opening the pay menu/submenu
RegisterNetEvent('mechanic:payMenu', function(vehicleData)
    local alert
    local vehicle = vehicleData.vehicle
    local fullName = vehicleData.fullName

    local healthPercentage, numberDoorsMissing, numberTyresBurst, repairCost, onlyHealthCost = determineVehicleDamage(vehicle)
    local onlyPercentageNumber = string.sub(healthPercentage, 1, -2)

    local vehicleProperties = {
        {
            title = 'Vehicle condition: ' .. healthPercentage,
            description = 'Your estimated vehicle condition',
            icon = 'percent',
            metadata = {
                {label = 'Cost', value = '$' .. onlyHealthCost}
            },
            readOnly = true,
            progress = onlyPercentageNumber
        },
        {
            title = 'Tyres burst: ' .. numberTyresBurst,
            description = 'The amount of tyres burst on your vehicle',
            icon = 'car-burst',
            metadata = {
                {label = 'Cost', value = '$' .. numberTyresBurst * Config.CarCosts[4].tyreCost }
            },
            readOnly = true
        },
        {
            title = 'Doors missing: ' .. numberDoorsMissing,
            description = 'The amount of doors missing on your vehicle',
            icon = 'truck-ramp-box',
            metadata = {
                {label = 'Cost', value = '$' .. numberDoorsMissing * Config.CarCosts[3].doorCost }
            },
            readOnly = true,
        }
    }

    if healthPercentage == 'Completely destroyed' or IsEntityOnFire(vehicle) then
        table.insert(vehicleProperties, {
            title = 'This vehicle cannot be repaired',
            icon = 'thumbs-up',
            disabled = true,
            icon = 'xmark',
            iconColor = 'red'
        })
    elseif repairCost > 0.0 then
        table.insert(vehicleProperties, {
            title = 'Pay $' .. repairCost .. ' to repair ' .. fullName .. '?',
            icon = 'money-check-dollar',
            onSelect = function()
                alert = showProceedAlert(fullName, repairCost)
                if alert == 'confirm' then
                    local playerCash = lib.callback.await('esx_GlassHeroes:requestPlayerMoney', source)
                    Wait(50)
                    local playerBankMoney = lib.callback.await('esx:GlassHeros:requestPlayerBankMoney', source)

                    Citizen.Wait(100)
                    if playerCash >= repairCost then
                        TriggerServerEvent('esx_GlassHeroes:removeMoney', repairCost)
                        local gotocar = pedGoToCar(vehicle, ped)

                        if gotocar == true then
                            isNPCworking = true
                            SetVehicleDoorsLocked(vehicle, 2)
                        end

                        targetVehicle = vehicleData.vehicle
                        ESX.ShowNotification("You have paid $" .. repairCost .. " in cash.", 'success', 3000)
                    elseif playerBankMoney >= repairCost then                     
                        TriggerServerEvent('esx_GlassHeroes:removeBankMoney', repairCost)
                        local gotocar = pedGoToCar(vehicle, ped)

                        if gotocar == true then
                            isNPCworking = true
                            SetVehicleDoorsLocked(vehicle, 2)
                        end

                        targetVehicle = vehicleData.vehicle
                        ESX.ShowNotification("You have paid $" .. repairCost .. " with your card.", 'success', 3000)
                    else
                        ESX.ShowNotification("You don't have enough money to repair this vehicle!", 'error', 3000)
                    end
                    
                end
            end,
            arrow = true,
            iconColor = 'green'
        })
    elseif repairCost == 0.0 then
        table.insert(vehicleProperties, {
            title = 'This vehicle has no damages to repair!',
            icon = 'thumbs-up',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'pay_menu',
        title = 'Would you like to repair this vehicle?',
        menu = 'mechanic_menu',
        options = vehicleProperties,
    })

    lib.showContext('pay_menu')
end)

-- Thread for blip, spawning NPC and ox_target
Citizen.CreateThread(function()
    addBlips()
    createdPeds = createPeds()

    exports.ox_target:addLocalEntity(createdPeds, {
        name = 'npc_talk',
        radius = 5,
        drawSprite = true,
        label = 'Talk',
        icon = 'fa-solid fa-comment',
        iconColor = 'white',
        distance = 2.0,
        onSelect = function(data)
            ped = data.entity
            TriggerEvent('esx_GlassHeroes:openDialogMenu')
        end, 
    
    })    
end)

-- Thread to check if NPC is near vehicle that is to be repaired
Citizen.CreateThread(function()
    while true do
        if isNPCworking then
            local pedCoords = GetEntityCoords(ped)
            local vehicleCoords = GetEntityCoords(targetVehicle)
            local distance = Vdist(pedCoords, vehicleCoords)
            
            if distance <= 1.9 then
                Citizen.Wait(2000)
                local heading = GetHeadingFromVector_2d(vehicleCoords.x - pedCoords.x, vehicleCoords.y - pedCoords.y)
                SetEntityHeading(ped, heading)
                pedRepairVehicle(targetVehicle, ped)
            end
            Citizen.Wait(500)
        else
            Citizen.Wait(2000)
        end
        
    end
end)

-- Thread to check if NPC has finished repairing
Citizen.CreateThread(function()
    while true do
        if hasFinishedWork and continueLoop then

            local pedCoords = GetEntityCoords(ped)
            local index = getPedIndex(ped)
            local distance = Vdist(pedCoords.x, pedCoords.y, pedCoords.z, Config.Peds[index].pedCoords)

            if distance <= 3.0 then
                TaskGoStraightToCoord(ped, Config.Peds[index].pedCoords, 2.0, -1, Config.Peds[index].pedHeading, 0.0)

                isNPCworking = false
                hasFinishedWork = false

                Citizen.Wait(5000)
                addClientPedProperties(ped)
                continueLoop = false
            end
            
            Citizen.Wait(1000)
        else
            Citizen.Wait(5000)
            continueLoop = true
        end
    end
end)