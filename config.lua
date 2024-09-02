Config = {}

Config.Peds = {
    {pedModel = GetHashKey('mp_m_waremech_01'), pedCoords = vector3(-229.74, -1377.23, 31.25-1), pedHeading = 212.60},
}

Config.mapBlip = {
    {blipIcon = 402},               --Blip icon on the map, standard: 402. If you'd like to change, visit https://docs.fivem.net/docs/game-references/blips/
    {blipColour = 5},               --Blip colour, standard: 5 (yellow)
    {blipScale = 1.5}               --Blip size, standard: 1.5
}

Config.CarCosts = {
    {costFactor = 1000.0},          --Cost factor that will change how price is calculated, standard: 1000.0
    {bumperCost = 478.00},          --Cost for a front/rear bumper, standard: 478.00
    {doorCost = 578.00},            --Cost for a door, standard: 578.00
    {tyreCost = 50.0}               --Cost for a tyre, standard: 50.0
}

Config.RepairTime = {
    {maxRepairCost = 5600},
    {maxRepairTime = 180000},
    {minRepairTime = 20000},
    {addedTime = 10000}
}

Config.Other = {
    {spawnRadius = 110.0},          --General radius to determine how close player is
    {infoBarRadius = 1.5},          --The radius for the info bar to pop up, standard: 1.5
    {fetchVehiclesRadius = 30.0}    --The radius to fetch nearby vehicles from, standard: 30.0
}