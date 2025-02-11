local Translations = {
    error = {
        not_your_vehicle = 'This is not your vehicle',
        no_parking_zone = 'You cannot park in this area',
        max_vehicles_reached = 'You have reached your maximum number of parked vehicles',
        vehicle_not_found = 'Vehicle not found',
        already_parked = 'This vehicle is already parked here',
        no_nearby_vehicles = 'No nearby vehicles found',
    },
    success = {
        vehicle_parked = 'Vehicle parked successfully',
        vehicle_retrieved = 'Vehicle retrieved successfully',
        position_saved = 'Vehicle position saved',
    },
    info = {
        checking_vehicles = 'Checking nearby vehicles...',
        vehicle_located = 'Vehicle located at marked position',
        approaching_limit = 'Warning: Approaching parking limit',
    },
    menu = {
        parking_menu = 'Parking Menu',
        park_vehicle = 'Park Vehicle',
        retrieve_vehicle = 'Retrieve Vehicle',
        vehicle_list = 'Parked Vehicles',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})