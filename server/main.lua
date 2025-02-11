local QBCore = exports['qb-core']:GetCoreObject()
local ParkedVehicles = {}
local SpawnedVehicles = {}

-- Inicialización de la base de datos
local function InitializeDatabase()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS enigma_parked_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            plate VARCHAR(8) NOT NULL,
            citizenid VARCHAR(50) NOT NULL,
            coords TEXT NOT NULL,
            heading FLOAT NOT NULL,
            model VARCHAR(50) NOT NULL,
            body_health FLOAT NOT NULL,
            engine_health FLOAT NOT NULL,
            fuel_level FLOAT NOT NULL,
            dirt_level FLOAT NOT NULL,
            mods TEXT,
            last_parked BIGINT NOT NULL,
            UNIQUE KEY unique_plate (plate),
            INDEX idx_citizenid (citizenid),
            INDEX idx_last_parked (last_parked)
        )
    ]])
end

local function CheckVehicleExists(plate, citizenid)
    if not plate or not citizenid then return false end
    
    local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        citizenid
    })
    
    return result ~= nil
end

-- Función para verificar si un vehículo ya está spawneado
local function IsVehicleSpawned(plate)
    return SpawnedVehicles[plate] ~= nil
end

-- Función para marcar un vehículo como spawneado
local function MarkVehicleAsSpawned(plate, source)
    SpawnedVehicles[plate] = {
        source = source,
        time = os.time()
    }
end

-- Función para desmarcar un vehículo spawneado
local function UnmarkVehicleAsSpawned(plate)
    if SpawnedVehicles[plate] then
        SpawnedVehicles[plate] = nil
    end
end

-- Función para limpiar vehículos spawneados
local function CleanupSpawnedVehicles()
    SpawnedVehicles = {}
end

-- Función para verificar propiedad del vehículo
local function CheckVehicleOwnership(citizenid, plate)
    local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid})
    return result ~= nil
end

-- Función para actualizar datos del vehículo
local function UpdateVehicleData(plate, data, citizenid)
    -- Verificar si existe
    local exists = MySQL.scalar.await('SELECT 1 FROM enigma_parked_vehicles WHERE plate = ?', {plate})
    
    if exists then
        MySQL.update('UPDATE enigma_parked_vehicles SET coords = ?, heading = ?, body_health = ?, engine_health = ?, fuel_level = ?, dirt_level = ?, mods = ?, last_parked = ? WHERE plate = ?',
        {
            json.encode(data.coords),
            data.heading,
            data.properties.bodyHealth or 1000.0,
            data.properties.engineHealth or 1000.0,
            data.properties.fuelLevel or 100.0,
            data.properties.dirtLevel or 0.0,
            json.encode(data.properties or {}),
            os.time(),
            plate
        })
    else
        MySQL.insert('INSERT INTO enigma_parked_vehicles (plate, citizenid, coords, heading, model, body_health, engine_health, fuel_level, dirt_level, mods, last_parked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            plate,
            citizenid,
            json.encode(data.coords),
            data.heading,
            data.properties.model or data.model,
            data.properties.bodyHealth or 1000.0,
            data.properties.engineHealth or 1000.0,
            data.properties.fuelLevel or 100.0,
            data.properties.dirtLevel or 0.0,
            json.encode(data.properties or {}),
            os.time()
        })
    end
end

-- Callbacks
QBCore.Functions.CreateCallback('enigma_parking:server:CheckVehicleOwner', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    
    cb(CheckVehicleOwnership(Player.PlayerData.citizenid, plate))
end)

QBCore.Functions.CreateCallback('enigma_parking:server:GetNearbyVehicles', function(source, cb, coords)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local vehicles = MySQL.query.await('SELECT * FROM enigma_parked_vehicles WHERE citizenid = ?', 
        {Player.PlayerData.citizenid})
    
    local nearbyVehicles = {}
    for _, vehicle in ipairs(vehicles or {}) do
        local vehicleCoords = json.decode(vehicle.coords)
        if vehicleCoords then
            local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z))
            if distance <= 100.0 then
                nearbyVehicles[#nearbyVehicles + 1] = vehicle
            end
        end
    end

    cb(nearbyVehicles)
end)

-- Eventos
RegisterNetEvent('enigma_parking:server:UpdateVehiclePosition', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local plate = data.plate
    if not plate then return end

    -- Verificar propiedad
    if not CheckVehicleOwnership(Player.PlayerData.citizenid, plate) then return end

    -- Actualizar datos
    UpdateVehicleData(plate, data, Player.PlayerData.citizenid)
end)

RegisterNetEvent('enigma_parking:server:RequestNearbyVehicles', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicles = MySQL.query.await('SELECT * FROM enigma_parked_vehicles WHERE citizenid = ?', 
        {Player.PlayerData.citizenid})
    
    if vehicles then
        for _, vehicleData in ipairs(vehicles) do
            local vehCoords = json.decode(vehicleData.coords)
            if vehCoords then
                local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(vehCoords.x, vehCoords.y, vehCoords.z))
                if distance <= 100.0 and not IsVehicleSpawned(vehicleData.plate) then
                    MarkVehicleAsSpawned(vehicleData.plate, src)
                    TriggerClientEvent('enigma_parking:client:RestoreVehicle', src, {
                        model = vehicleData.model,
                        plate = vehicleData.plate,
                        coords = vehCoords,
                        heading = vehicleData.heading,
                        properties = json.decode(vehicleData.mods or '{}'),
                        bodyHealth = vehicleData.body_health,
                        engineHealth = vehicleData.engine_health,
                        fuelLevel = vehicleData.fuel_level,
                        dirtLevel = vehicleData.dirt_level
                    })
                end
            end
        end
    end
end)

RegisterNetEvent('enigma_parking:server:RequestAllVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicles = MySQL.query.await([[
        SELECT pv.*, epv.coords, epv.heading, epv.mods, epv.body_health, epv.engine_health, epv.fuel_level, epv.dirt_level
        FROM player_vehicles pv 
        LEFT JOIN enigma_parked_vehicles epv ON pv.plate = epv.plate 
        WHERE pv.citizenid = ?
    ]], {Player.PlayerData.citizenid})

    if vehicles then
        for _, vehicle in ipairs(vehicles) do
            local coords = json.decode(vehicle.coords) or {x = -30.69, y = -1089.55, z = 26.42}
            local heading = vehicle.heading or 70.23
            
            -- Solo restaurar si no está ya spawneado
            if not IsVehicleSpawned(vehicle.plate) then
                MarkVehicleAsSpawned(vehicle.plate, src)
                TriggerClientEvent('enigma_parking:client:RestoreVehicle', src, {
                    model = vehicle.vehicle,
                    plate = vehicle.plate,
                    coords = coords,
                    heading = heading,
                    properties = json.decode(vehicle.mods or '{}'),
                    bodyHealth = vehicle.body_health or 1000.0,
                    engineHealth = vehicle.engine_health or 1000.0,
                    fuelLevel = vehicle.fuel_level or 100.0,
                    dirtLevel = vehicle.dirt_level or 0.0
                })
            end
        end
    end
end)

RegisterNetEvent('enigma_parking:server:VehicleRemoved', function(plate)
    UnmarkVehicleAsSpawned(plate)
end)

-- Threads
CreateThread(function()
    InitializeDatabase()
    -- Cargar vehículos en memoria
    local vehicles = MySQL.query.await('SELECT * FROM enigma_parked_vehicles')
    if vehicles then
        for _, vehicle in ipairs(vehicles) do
            ParkedVehicles[vehicle.plate] = {
                citizenid = vehicle.citizenid,
                coords = json.decode(vehicle.coords),
                heading = vehicle.heading,
                model = vehicle.model,
                properties = json.decode(vehicle.mods or '{}'),
                lastParked = vehicle.last_parked
            }
        end
    end
end)

-- Thread para limpiar vehículos viejos
CreateThread(function()
    while true do
        Wait(3600000) -- Cada hora
        local currentTime = os.time()
        local maxAge = 72 * 3600 -- 72 horas

        MySQL.query('DELETE FROM enigma_parked_vehicles WHERE last_parked < ?', 
            {currentTime - maxAge})

        -- Limpiar cache local
        for plate, data in pairs(ParkedVehicles) do
            if (currentTime - data.lastParked) > maxAge then
                ParkedVehicles[plate] = nil
            end
        end
    end
end)

-- Eventos del framework
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Cargar vehículos del jugador
    local vehicles = MySQL.query.await('SELECT * FROM enigma_parked_vehicles WHERE citizenid = ?', 
        {Player.PlayerData.citizenid})

    if vehicles then
        for _, vehicleData in ipairs(vehicles) do
            if not IsVehicleSpawned(vehicleData.plate) then
                local coords = json.decode(vehicleData.coords)
                if coords then
                    MarkVehicleAsSpawned(vehicleData.plate, src)
                    TriggerClientEvent('enigma_parking:client:RestoreVehicle', src, {
                        model = vehicleData.model,
                        plate = vehicleData.plate,
                        coords = coords,
                        heading = vehicleData.heading,
                        properties = json.decode(vehicleData.mods or '{}'),
                        bodyHealth = vehicleData.body_health,
                        engineHealth = vehicleData.engine_health,
                        fuelLevel = vehicleData.fuel_level,
                        dirtLevel = vehicleData.dirt_level
                    })
                end
            end
        end
    end
end)

-- Cleanup al desconectar
AddEventHandler('playerDropped', function()
    local src = source
    -- Limpiar vehículos spawneados por este jugador
    for plate, data in pairs(SpawnedVehicles) do
        if data.source == src then
            UnmarkVehicleAsSpawned(plate)
        end
    end
end)

-- Eventos de recursos
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        InitializeDatabase()
        CleanupSpawnedVehicles()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupSpawnedVehicles()
    end
end)