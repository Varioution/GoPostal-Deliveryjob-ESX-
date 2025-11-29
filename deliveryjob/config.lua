Config = {}

-- Depotlocatie
Config.Depot = {
    -- GoPostal hoofdkantoor
    coords = vec3(133.054947, 96.514290, 83.502563),
    radius = 35.0,
    pedSpawn = vec4(133.054947, 96.514290, 83.502563, 155.905502),
    blip = { sprite = 478, color = 5, scale = 0.95 }
}

-- leveringsadres formaat zo schrijf je het { name 'Adresnaam' pos vec3(x y z) }
Config.DeliveryPoints = {
    { name = 'Mirror Park - Nikola Pl', pos = vec3(1262.0, -429.8, 69.0), front = vec3(1261.8, -431.0, 69.0), nh = { vec3(1264.7, -435.2, 68.6), vec3(1259.4, -435.6, 68.3) } },
    { name = 'Mirror Park - Bridge St', pos = vec3(1085.1, -437.2, 66.4), front = vec3(1084.8, -438.5, 66.4), nh = { vec3(1087.7, -442.0, 66.1), vec3(1081.9, -441.8, 66.0) } },
    { name = 'Vespucci Canals - Bay City Ave', pos = vec3(-1093.002, -1607.881, 8.453), front = vec3(-1093.45, -1609.30, 8.35), nh = { vec3(-1096.10, -1614.50, 4.15) } },
    { name = 'Vespucci Beach - Magellan Ave', pos = vec3(-1150.404, -1473.956, 4.375), front = vec3(-1149.90, -1475.40, 4.30), nh = { vec3(-1146.30, -1477.90, 3.90) } },
    { name = 'Del Perro - Marathon Ave', pos = vec3(-1370.703, -503.604, 33.155), front = vec3(-1372.00, -504.60, 33.05), nh = { vec3(-1376.90, -506.90, 32.40) } },
    { name = 'Rockford Hills - Portola Dr', pos = vec3(-667.0, -186.2, 37.8), front = vec3(-666.6, -187.4, 37.7), nh = { vec3(-669.8, -190.6, 37.3) } },
    { name = 'Burton - Hawick Ave', pos = vec3(-349.2, -130.5, 39.4), front = vec3(-349.5, -131.8, 39.3), nh = { vec3(-352.9, -135.6, 38.9) } },
    { name = 'Little Seoul - Calais Ave', pos = vec3(-498.3, -679.4, 33.2), front = vec3(-498.7, -680.6, 33.1), nh = { vec3(-501.4, -683.9, 32.8) } },
}

-- Aantal stops per route
Config.DeliveriesPerRoute = 20

-- Betaling per drop (per pakket)
Config.PayPerDrop = 400
-- Uitbetaling als item (bijv. 'money' of 'cash')
Config.PayItem = 'money'
-- Extra bonus 
Config.FinishBonusPerDrop = 0

-- Afstandstolerantie rondom afleverpunt
Config.DeliverRadius = 4.0

-- Voertuigmodel
Config.VehicleModel = 'boxville2'

-- Meerdere spawnpoints bij GoPostal
Config.VehicleSpawns = {
    vec4(72.909889, 119.169235, 79.071045, 155.905502),
    vec4(59.670330, 125.367035, 79.138428, 158.740158),
    vec4(66.896706, 123.178024, 79.037354, 155.905502)
}

-- Vereiste jobnaam
Config.RequiredJob = 'deliverer'
-- Eigen marker boven voertuig
Config.OwnerMarker = true

-- Boxprop in busje
Config.BoxModel = 'prop_cs_cardbox_01'
Config.BoxOffsets = {
    vec3(-0.40, -2.50, 0.33), vec3(-0.20, -2.50, 0.33), vec3(0.00, -2.50, 0.33), vec3(0.20, -2.50, 0.33), vec3(0.40, -2.50, 0.33),
    vec3(-0.40, -2.10, 0.33), vec3(-0.20, -2.10, 0.33), vec3(0.00, -2.10, 0.33), vec3(0.20, -2.10, 0.33), vec3(0.40, -2.10, 0.33),
    vec3(-0.40, -1.70, 0.33), vec3(-0.20, -1.70, 0.33), vec3(0.00, -1.70, 0.33), vec3(0.20, -1.70, 0.33), vec3(0.40, -1.70, 0.33),
    vec3(-0.40, -1.30, 0.33), vec3(-0.20, -1.30, 0.33), vec3(0.00, -1.30, 0.33), vec3(0.20, -1.30, 0.33), vec3(0.40, -1.30, 0.33)
}

Config.DropMarker = { r = 50, g = 150, b = 255 }

-- Kans dat handtekening verplicht is bij bezorging
Config.SignatureChance = 0.00

-- Kans dat bewoner niet thuis is
Config.NotHomeChance = 0.90


-- Teksten voor meldingen
Config.Texts = {
    NotHome = 'Niemand thuis. Leg het pakket in de tuin',
    NeedSignature = 'Handtekening nodig voor deze bezorging',
    PickupReady = 'Bewoner heeft een pakket klaargezet om op te halen',
    PickupTaken = 'Pakket opgehaald. Leg het in de bus'
}

-- Pickups kans per adres
Config.PickupChance = 0.00

-- Radius voor achtertuin drop
Config.BackDropRadius = 3.5