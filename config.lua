Config = {}

-- Configuración general
Config.Debug = false
Config.SaveInterval = 30000 -- Guardar posición cada 30 segundos
Config.MinDistanceToSave = 5.0 -- Distancia mínima para actualizar posición
Config.MaxParkedTime = 72 -- Tiempo máximo en horas

-- Configuración de zonas restringidas
Config.NoParking = {
    {
        coords = vector3(231.93, -779.54, 30.64),
        radius = 20.0,
        name = "Hospital Parking"
    },
    -- Añadir más zonas según sea necesario
}

-- Configuración de degradación de vehículos
Config.VehicleDegradation = {
    enabled = true,
    interval = 3600000, -- Comprobar cada hora
    healthDecrease = 0.5, -- Porcentaje de salud que pierde por hora
    fuelDecrease = 0.2, -- Porcentaje de combustible que pierde por hora
    minimumHealth = 500.0, -- Salud mínima del vehículo
    minimumFuel = 5.0, -- Combustible mínimo
}

-- Configuración de notificaciones
Config.Notifications = {
    enabled = true,
    healthThreshold = 600.0, -- Notificar cuando la salud baje de este valor
    fuelThreshold = 20.0, -- Notificar cuando el combustible baje de este porcentaje
}

-- Configuración de respawn de vehículos
Config.VehicleRespawn = {
    enabled = true,
    maxDistance = 100.0, -- Distancia máxima para hacer respawn de vehículos
    checkInterval = 10000, -- Intervalo para comprobar vehículos cercanos
}

-- Límites por jugador
Config.PlayerLimits = {
    maxVehicles = 5, -- Máximo de vehículos que un jugador puede tener fuera
    warningThreshold = 4 -- Avisar cuando el jugador está cerca del límite
}