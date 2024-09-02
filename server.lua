local isPedSpawned = false

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