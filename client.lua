--Variables
local pedVector3 = Config.Peds[1].pedCoords
local spawnRadius = Config.Other[1].spawnRadius
local infoBarRadius = Config.Other[2].infoBarRadius

local isNearPed = false
local displayInfobar = false
local isNPCworking = false
local hasFinishedWork = false
local continueLoop = true

local ped = nil
local targetVehicle = nil

local playerBankMoney = 0
local playerCash = 0
local mechanicsOnline = 0

RegisterNetEvent('esx_GlassHeroes:getPlayerBankMoney')
AddEventHandler('esx_GlassHeroes:getPlayerBankMoney', function(bankMoney)
    playerBankMoney = bankMoney
end)

RegisterNetEvent('esx_GlassHeroes:getPlayerMoney')
AddEventHandler('esx_GlassHeroes:getPlayerMoney', function(cash)
    playerCash = cash
end)

RegisterNetEvent('npc:spawnPed')
AddEventHandler('npc:spawnPed', function()
    createPed()
end)

RegisterNetEvent('npc:removePed')
AddEventHandler('npc:removePed', function()
    removePed()
end)

RegisterNetEvent('npc:hasFinishedWorkTrue')
AddEventHandler('npc:hasFinishedWorkTrue', function()
    hasFinishedWork = true
end)

RegisterNetEvent('npc:isNPCworkingFalse')
AddEventHandler('npc:isNPCworkingFalse', function()
    isNPCworking = false
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    TriggerServerEvent('npc:despawn')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    TriggerServerEvent('npc:despawn')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('npc:spawn')
    end
end)

RegisterNetEvent('esx_GlassHeroes:getMechanicsOnline')
AddEventHandler('esx_GlassHeroes:getMechanicsOnline', function(amount)
    mechanicsOnline = amount
end)

--Event for opening the pay menu/submenu
RegisterNetEvent('mechanic:payMenu')
AddEventHandler('mechanic:payMenu', function(vehicleData)
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
                    TriggerServerEvent('esx_GlassHeroes:requestPlayerBankMoney')
                    TriggerServerEvent('esx_GlassHeroes:requestPlayerMoney')
                    Citizen.Wait(100)
                    if playerCash >= repairCost then
                       TriggerServerEvent('esx_GlassHeroes:removeMoney', repairCost)
                        local gotocar, newPed = pedGoToCar(vehicle)

                        if gotocar == true then
                            isNPCworking = true
                            SetVehicleDoorsLocked(vehicle, 2)
                        end

                        ped = newPed
                        targetVehicle = vehicleData.vehicle
                        ESX.ShowNotification("You have paid $" .. repairCost .. " with cash.", 'success', 3000)
                    elseif playerBankMoney >= repairCost then
                        TriggerServerEvent('esx_GlassHeroes:removeBankMoney', repairCost)
                        local gotocar, newPed = pedGoToCar(vehicle)

                        if gotocar == true then
                            isNPCworking = true
                        end

                        ped = newPed
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

--Thread to check if player is in or out of range
Citizen.CreateThread(function()
    while true do

        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = Vdist(playerCoords, pedVector3)

        if distance <= spawnRadius and not isNearPed then
            isNearPed = true
        elseif distance >= spawnRadius and isNearPed then
            isNearPed = false
        end

        if distance <= infoBarRadius and isNearPed then
            displayInfobar = true
        else
            displayInfobar = false
        end

        Citizen.Wait(1000)
    end
end)

--Thread for blip and spawning NPC
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.Peds[1].pedCoords)
    SetBlipSprite(blip, Config.mapBlip[1].blipIcon)
    SetBlipColour(blip, Config.mapBlip[2].blipColour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, Config.mapBlip[3].blipScale)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Glass Heroes')
    EndTextCommandSetBlipName(blip)

    TriggerServerEvent('npc:spawn') 
    
end)

--Thread for alert if player is near NPC
Citizen.CreateThread(function()
    while true do
        if not isNPCworking and not IsPedInAnyVehicle(PlayerPedId(), true) then
            if displayInfobar then
                showInfobar('Press ~INPUT_CONTEXT~ to choose a vehicle to repair.')

                if IsControlJustReleased(1, 38) then
                    if Config.Features[1].requireNoMechanics then
                        if mechanicsOnline < Config.Features[1].amountOfMechanics then
                            openDialogMenu()
                        else
                            ESX.ShowNotification(Config.Features[1].errorMessage, 'error', 3000)
                        end
                    else
                        openDialogMenu()
                    end
                end

                Citizen.Wait(1)
            else
                Citizen.Wait(500)
            end
        else
            displayInfobar = false
            Citizen.Wait(500)
        end       
    end
end)

--Thread to check if NPC is near vehicle that is to be repaired
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
                pedRepairVehicle(targetVehicle)
            end
            Citizen.Wait(500)
        else
            Citizen.Wait(2000)
        end
        
    end
end)

--Thread to check if NPC has finished repairing
Citizen.CreateThread(function()
    while true do
        if hasFinishedWork and continueLoop then
            local pedCoords = GetEntityCoords(ped)
            
            local distance = Vdist(pedCoords.x, pedCoords.y, pedCoords.z, currentPed.pedCoords)

            if distance <= 3.0 then
                TaskGoStraightToCoord(ped, Config.Peds[1].pedCoords, 2.0, -1, currentPed.pedCoords, 0.0)
                isNPCworking = false
                hasFinishedWork = false
                Citizen.Wait(5000)
                addPedProperties(ped)
                continueLoop = false
            end
            
            Citizen.Wait(1000)
        else
            Citizen.Wait(5000)
            continueLoop = true
        end
    end
end)

--Thread to check for mechanics
Citizen.CreateThread(function()
    while true do
        if Config.Features[1].requireNoMechanics then
            TriggerServerEvent('esx_GlassHeroes:requestMechanicsOnline')
            Citizen.Wait(3000)
        else
            Citizen.Wait(5000)
        end
        
    end
end)