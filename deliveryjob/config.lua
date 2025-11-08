Config = {}

-- depot locatie
Config.Depot = {
    -- GoPostal hoofdkantoor
    coords = vec3(133.054947, 96.514290, 83.502563),
    radius = 35.0,
    pedSpawn = vec4(133.054947, 96.514290, 83.502563, 155.905502),
    blip = { sprite = 478, color = 5, scale = 0.95 }
}

-- formaat: { name = 'Adresnaam', pos = vec3(x, y, z) }
Config.DeliveryPoints = {
    { name = 'Vespucci Canals - Bay City Ave', pos = vec3(-1093.002197, -1607.881348, 8.453491) },
    { name = 'Vespucci Beach - Magellan Ave', pos = vec3(-1150.404419, -1473.956055, 4.375854) },
    { name = 'Del Perro - Marathon Ave', pos = vec3(-1370.703247, -503.604401, 33.155273)},
    { name = 'Rockford Hills - Portola Dr', pos = vec3(-667.0, -186.2, 37.8) },
    { name = 'Burton - Hawick Ave', pos = vec3(-349.2, -130.5, 39.4) },
    { name = 'Little Seoul - Calais Ave', pos = vec3(-498.3, -679.4, 33.2) },
    { name = 'Pillbox Hill - Power St', pos = vec3(136.5, -936.3, 29.7) },
    { name = 'Legion Square - Vespucci Blvd', pos = vec3(154.7, -1011.2, 29.3) },
    { name = 'Mission Row - Sinner St', pos = vec3(441.2, -981.7, 30.7) },
    { name = 'La Mesa - Popular St', pos = vec3(795.4, -728.1, 28.0) },
    { name = 'Mirror Park - West Mirror Dr', pos = vec3(1265.0, -564.0, 68.6) },
    { name = 'Vinewood - Alta St', pos = vec3(254.3, 223.9, 106.3) },
    { name = 'Downtown Vinewood - Vinewood Blvd', pos = vec3(461.2, 179.1, 102.1) },
    { name = 'Hawick - Spanish Ave', pos = vec3(-27.6, -142.2, 57.2) },
    { name = 'Sandy Shores - Alhambra Dr', pos = vec3(1851.3, 3683.5, 34.2) },
    { name = 'Grapeseed - Main St', pos = vec3(1698.3, 4785.7, 42.1) },
    { name = 'Paleto Bay - Paleto Blvd', pos = vec3(-128.9, 6396.7, 31.6) },
    { name = 'Chumash - Great Ocean Hwy', pos = vec3(-2978.3, 450.1, 14.7) },
    { name = 'Banham Canyon - Banham Dr', pos = vec3(-2992.5, 733.2, 27.6) },
    { name = 'Harmony - Route 68', pos = vec3(557.7, 2662.3, 42.0) },
    { name = 'Davis - Grove St', pos = vec3(-79.6, -1620.9, 31.6) },
    { name = 'Strawberry - Innocence Blvd', pos = vec3(253.4, -1586.2, 29.0) },
    { name = 'Rancho - Jamestown St', pos = vec3(437.8, -1512.1, 29.3) },
    { name = 'East Vinewood - El Rancho Blvd', pos = vec3(999.8, -293.2, 67.9) }
}

-- aantal drops per route
Config.DeliveriesPerRoute = 20

-- betaling per drop
-- vaste betaling per pakket, uitbetaald bij uitdienst
Config.PayPerDrop = 400
-- uitbetaling als item (bijv. 'money' of 'cash')
Config.PayItem = 'money'
-- extra beloning per bezorgde box bij afronden (finish). 0 = uit.
Config.FinishBonusPerDrop = 0

-- afstand check
Config.DeliverRadius = 4.0

-- voertuig model
Config.VehicleModel = 'boxville2'

-- meerdere spawnpoints bij GoPostal
Config.VehicleSpawns = {
    vec4(72.909889, 119.169235, 79.071045, 155.905502),
    vec4(59.670330, 125.367035, 79.138428, 158.740158),
    vec4(66.896706, 123.178024, 79.037354, 155.905502)
}

-- vereiste SQL naam
Config.RequiredJob = 'deliverer'
-- eigen marker boven voertuig
Config.OwnerMarker = true

-- box props in busje
Config.BoxModel = 'prop_cs_cardbox_01'
Config.BoxOffsets = {
    vec3(-0.30, -2.40, 0.33), vec3(-0.15, -2.40, 0.33), vec3(0.0, -2.40, 0.33), vec3(0.15, -2.40, 0.33), vec3(0.30, -2.40, 0.33),
    vec3(-0.30, -2.10, 0.33), vec3(-0.15, -2.10, 0.33), vec3(0.0, -2.10, 0.33), vec3(0.15, -2.10, 0.33), vec3(0.30, -2.10, 0.33),
    vec3(-0.30, -1.80, 0.33), vec3(-0.15, -1.80, 0.33), vec3(0.0, -1.80, 0.33), vec3(0.15, -1.80, 0.33), vec3(0.30, -1.80, 0.33),
    vec3(-0.30, -1.50, 0.33), vec3(-0.15, -1.50, 0.33), vec3(0.0, -1.50, 0.33), vec3(0.15, -1.50, 0.33), vec3(0.30, -1.50, 0.33)
}

-- marker kleur bij neerleggen
Config.DropMarker = { r = 50, g = 150, b = 255 }