local isPedSpawned = false

lib.callback.register('esx:GlassHeros:requestPlayerBankMoney', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local bankMoney = xPlayer.getAccount('bank').money
    
    return bankMoney
end)

lib.callback.register('esx_GlassHeroes:requestPlayerMoney', function(source)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local cash = xPlayer.getMoney()

    return cash
end)

lib.callback.register('esx_GlassHeroes:requestMechanicsOnline', function(source)
    local xPlayers = ESX.GetExtendedPlayers()
    local mechanicsOnline = 0


    for _, xPlayer in pairs(xPlayers) do
        if (xPlayer.job.name == 'mechanic') then
            mechanicsOnline = mechanicsOnline + 1
        end
    end


    return mechanicsOnline
end)

RegisterServerEvent('npc:spawn', function()
    if not isPedSpawned then
        isPedSpawned = true
        TriggerClientEvent('npc:spawnPed', -1)
    end
end)

RegisterServerEvent('npc:despawn', function()
    if isPedSpawned then
        isPedSpawned = false
        TriggerClientEvent('npc:removePed', -1)
    end
end)

RegisterNetEvent('esx_GlassHeroes:removeMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.removeMoney(amount)
end)


RegisterNetEvent('esx_GlassHeroes:removeBankMoney', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.removeAccountMoney('bank', amount)
end)
