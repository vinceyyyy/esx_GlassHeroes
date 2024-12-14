-- Callbacks
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
    local xPlayers = ESX.GetExtendedPlayers('job', "mechanic")
    local mechanicsOnline = #xPlayers

    return mechanicsOnline
end)

-- Remove player money
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