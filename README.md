# Enigma Parking System
A realistic parking system for FiveM that allows vehicles to maintain their position after restarting the server.
Features

Automatic position saving system
Restoration of vehicles after reboot
Integration with QB-Core
Vehicle anti-duplication system
Preservation of vehicle modifications and status
Compatibility with enigma_autoshop

### Dependencies

QB-Core Framework
oxmysql
LegacyFuel

### Installation

Download Resource

Download the enigma_parking resource
Place it in your resources folder


### Database Configuration

#### Execute the following SQL query in your database:
```lua
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
);
```
### Resource Installation

Add the following to your server.cfg:
```lua
ensure enigma_parking
```
#### Integration with enigma_autoshop

If you are using enigma_autoshop, make sure enigma_parking is started after
```lua
ensure enigma_autoshop
ensure enigma_parking
```

### Configuration

Edit config.lua

Adjust the following values according to your needs:
```lua
Config = {
    SaveInterval = 30000, -- Intervalo de guardado (ms)
    MaxParkedTime = 72,   -- Tiempo máximo aparcado (horas)
    MinDistanceToSave = 3.0, -- Distancia mínima para actualizar
    RestoreDistance = 100.0 -- Distancia para cargar vehículos
}
```

### No Parking Zones (Optional)

Configures zones where parking is not allowed:
```lua
Config.NoParking = {
    {
        coords = vector3(231.93, -779.54, 30.64),
        radius = 20.0,
        name = “Hospital Parking”
    }
}
```


## Usage
The system works automatically:

Vehicles are automatically saved each time they are stopped.
When restarting the server, the vehicles appear at their last location.
Vehicle modifications and status are maintained

## Troubleshooting

Duplicate vehicles

- Check that no other resources are spawning vehicles.
- Make sure enigma_parking is loaded after other vehicle resources


## Vehicles Not Appearing

- Check that the database is configured correctly
- Check server logs for errors
- Make sure that the coordinates are within valid range


## SQL error

- Make sure the table is created correctly
- Verify that oxmysql is working properly

---
## Support
For support and bug reports:

Create an issue in the repository
Provide server logs
Describe the problem in detail

## Credits
Developed by [R1musTAP].
