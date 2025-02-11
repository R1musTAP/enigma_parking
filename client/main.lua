local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local spawnedVehicles = {}
local lastSavedPositions = {}
local isSpawning = false
local isInitialized = false
local lastCoords = nil

-- Función para obtener propiedades del vehículo
local function GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    if not vehicleProps then return nil end

    -- Propiedades adicionales
    vehicleProps.fuelLevel = exports['LegacyFuel']:GetFuel(vehicle)
    vehicleProps.bodyHealth = GetVehicleBodyHealth(vehicle)
    vehicleProps.engineHealth = GetVehicleEngineHealth(vehicle)
    vehicleProps.tankHealth = GetVehiclePetrolTankHealth(vehicle)
    vehicleProps.dirtLevel = GetVehicleDirtLevel(vehicle)

    return vehicleProps
end

-- Función para aplicar propiedades al vehículo
local function SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end

    QBCore.Functions.SetVehicleProperties(vehicle, props)

    if props.fuelLevel then exports['LegacyFuel']:SetFuel(vehicle, props.fuelLevel) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel) end
end

-- Función para restaurar vehículo
local function RestoreVehicle(data)
    if not data or not data.plate then return end
    
    -- Verificar si ya existe un vehículo con esta placa
    if spawnedVehicles[data.plate] then
        if DoesEntityExist(spawnedVehicles[data.plate]) then
            SetVehicleProperties(spawnedVehicles[data.plate], data.properties)
            return
        else
            spawnedVehicles[data.plate] = nil
            TriggerServerEvent('enigma_parking:server:VehicleRemoved', data.plate)
        end
    end

    -- Verificar vehículos cercanos
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle) == data.plate then
            SetVehicleProperties(vehicle, data.properties)
            spawnedVehicles[data.plate] = vehicle
            return
        end
    end

    -- Cargar modelo
    local hash = GetHashKey(data.model)
    RequestModel(hash)
    
    local timeoutCounter = 0
    while not HasModelLoaded(hash) do
        Wait(0)
        timeoutCounter = timeoutCounter + 1
        if timeoutCounter > 50 then return end
    end

    -- Crear vehículo
    local vehicle = CreateVehicle(hash, data.coords.x, data.coords.y, data.coords.z, data.heading, true, true)
    
    -- Configuración
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleOnGroundProperly(vehicle)
    
    -- Aplicar propiedades
    if data.properties then
        SetVehicleProperties(vehicle, data.properties)
    else
        -- Propiedades por defecto
        SetVehicleBodyHealth(vehicle, data.bodyHealth or 1000.0)
        SetVehicleEngineHealth(vehicle, data.engineHealth or 1000.0)
        exports['LegacyFuel']:SetFuel(vehicle, data.fuelLevel or 100.0)
    end

    -- Llaves y bloqueo
    TriggerServerEvent('vehiclekeys:server:GiveVehicleKeys', data.plate, GetPlayerServerId(PlayerId()))
    SetVehicleDoorsLocked(vehicle, 1) -- 1 = desbloqueado
    
    -- Registrar vehículo
    spawnedVehicles[data.plate] = vehicle
    
    SetModelAsNoLongerNeeded(hash)
end

-- Thread para guardar posición automáticamente
CreateThread(function()
    while true do
        Wait(10000) -- Cada 10 segundos
        if isInitialized then
            local playerPed = PlayerPedId()
            
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if DoesEntityExist(vehicle) then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    
                    QBCore.Functions.TriggerCallback('enigma_parking:server:CheckVehicleOwner', function(isOwner)
                        if isOwner then
                            local coords = GetEntityCoords(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            
                            -- Solo guardar si se ha movido lo suficiente
                            if not lastSavedPositions[plate] or #(lastSavedPositions[plate].coords - coords) > 3.0 then
                                lastSavedPositions[plate] = {
                                    coords = coords,
                                    heading = heading
                                }
                                
                                local vehicleProps = GetVehicleProperties(vehicle)
                                
                                TriggerServerEvent('enigma_parking:server:UpdateVehiclePosition', {
                                    plate = plate,
                                    coords = coords,
                                    heading = heading,
                                    properties = vehicleProps
                                })
                            end
                        end
                    end, plate)
                end
            end
        end
    end
end)

-- Thread para guardar cuando el vehículo se detiene
CreateThread(function()
    while true do
        Wait(1000)
        if isInitialized then
            local playerPed = PlayerPedId()
            
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if DoesEntityExist(vehicle) and IsVehicleStopped(vehicle) then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    
                    QBCore.Functions.TriggerCallback('enigma_parking:server:CheckVehicleOwner', function(isOwner)
                        if isOwner then
                            local coords = GetEntityCoords(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            local vehicleProps = GetVehicleProperties(vehicle)
                            
                            TriggerServerEvent('enigma_parking:server:UpdateVehiclePosition', {
                                plate = plate,
                                coords = coords,
                                heading = heading,
                                properties = vehicleProps,
                                stopped = true
                            })
                        end
                    end, plate)
                end
            end
        end
    end
end)

-- Thread para verificar vehículos spawneados
CreateThread(function()
    while true do
        Wait(5000) -- Cada 5 segundos
        for plate, vehicle in pairs(spawnedVehicles) do
            if not DoesEntityExist(vehicle) then
                spawnedVehicles[plate] = nil
                TriggerServerEvent('enigma_parking:server:VehicleRemoved', plate)
            end
        end
    end
end)

-- Eventos
RegisterNetEvent('enigma_parking:client:RestoreVehicle', function(data)
    RestoreVehicle(data)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isInitialized = true
    TriggerServerEvent('enigma_parking:server:RequestAllVehicles')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isInitialized = false
    -- Limpiar vehículos spawneados
    for plate, vehicle in pairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    spawnedVehicles = {}
end)

-- Cleanup al detener el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Guardar estado final y eliminar vehículos
        for plate, vehicle in pairs(spawnedVehicles) do
            if DoesEntityExist(vehicle) then
                local coords = GetEntityCoords(vehicle)
                local heading = GetEntityHeading(vehicle)
                local props = GetVehicleProperties(vehicle)
                
                TriggerServerEvent('enigma_parking:server:UpdateVehiclePosition', {
                    plate = plate,
                    coords = coords,
                    heading = heading,
                    properties = props,
                    final = true
                })
                
                DeleteEntity(vehicle)
            end
            TriggerServerEvent('enigma_parking:server:VehicleRemoved', plate)
        end
        spawnedVehicles = {}
    end
end)

-- Al iniciar el recurso
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if LocalPlayer.state.isLoggedIn then
            PlayerData = QBCore.Functions.GetPlayerData()
            isInitialized = true
            TriggerServerEvent('enigma_parking:server:RequestAllVehicles')
        end
    end
end)