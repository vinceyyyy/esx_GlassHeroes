local isPedSpawned = false
local mechanicsOnline = 0

RegisterServerEvent('npc:spawn')
AddEventHandler('npc:spawn', function()
    if not isPedSpawned then
        isPedSpawned = true
        TriggerClientEvent('npc:spawnPed', -1)
    end
end)

RegisterServerEvent('npc:despawn')
AddEventHandler('npc:despawn', function()
    if isPedSpawned then
        isPedSpawned = false
        TriggerClientEvent('npc:removePed', -1)
    end
end)

RegisterNetEvent('esx_GlassHeroes:removeMoney')
AddEventHandler('esx_GlassHeroes:removeMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.removeMoney(amount)
end)

RegisterServerEvent('esx_GlassHeroes:requestPlayerBankMoney')
AddEventHandler('esx_GlassHeroes:requestPlayerBankMoney', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local bankMoney = xPlayer.getAccount('bank').money

    TriggerClientEvent('esx_GlassHeroes:getPlayerBankMoney', source, bankMoney)
    
end)

RegisterNetEvent('esx_GlassHeroes:removeBankMoney')
AddEventHandler('esx_GlassHeroes:removeBankMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.removeAccountMoney('bank', amount)
end)

RegisterServerEvent('esx_GlassHeroes:requestPlayerMoney')
AddEventHandler('esx_GlassHeroes:requestPlayerMoney', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local cash = xPlayer.getMoney()

    TriggerClientEvent('esx_GlassHeroes:getPlayerMoney', source, cash)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    mechanicsOnline = 0

    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if (xPlayer.job.name == 'mechanic') then
            mechanicsOnline = mechanicsOnline + 1
        end
    end
end)

RegisterNetEvent('esx:setJob', function(player, newJob, lastJob)
    local xPlayer = ESX.GetPlayerFromId(player)

    if newJob.name == 'mechanic' and lastJob.name ~= 'mechanic' then
        mechanicsOnline = mechanicsOnline + 1
    elseif newJob.name ~= 'mechanic' and lastJob.name == 'mechanic' then
        mechanicsOnline = mechanicsOnline - 1
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer and xPlayer.job.name == 'mechanic' then
        mechanicsOnline = mechanicsOnline - 1
    end
end)

AddEventHandler('esx:playerLoaded', function(player, xPlayer, isNew)
    if xPlayer.job.name == 'mechanic' then
        mechanicsOnline = mechanicsOnline + 1
    end
end)

RegisterNetEvent('esx_GlassHeroes:requestMechanicsOnline')
AddEventHandler('esx_GlassHeroes:requestMechanicsOnline', function()
    TriggerClientEvent('esx_GlassHeroes:getMechanicsOnline', source, mechanicsOnline)
end)