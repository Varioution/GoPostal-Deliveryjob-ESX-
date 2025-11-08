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
