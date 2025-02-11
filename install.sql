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