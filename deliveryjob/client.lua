local ESX = exports['es_extended']:getSharedObject()

local state = {
    active = false,
    route = nil,
    idx = 0,
    blip = nil,
    targetPoint = nil,
    veh = nil,
    depotBlip = nil,
    depotPed = nil,
    dropPed = nil,
    done = false,
    prevAppearance = nil,
    vehNetId = nil,
    carrying = false,
    carryProp = nil,
    vanBoxes = {},
    lastSummaryDrops = 0
}
local function notify(msg)
    lib.notify({ title = 'Pakket', description = msg, type = 'inform' })
end

-- check of achterdeuren open staan (minimaal één deur)
local function rearDoorsOpen()
    if not (state.veh and DoesEntityExist(state.veh)) then return false end
    local left = GetVehicleDoorAngleRatio(state.veh, 2) or 0.0
    local right = GetVehicleDoorAngleRatio(state.veh, 3) or 0.0
    return (left > 0.1) or (right > 0.1)
end

-- text ui stijl
local function showUI(text, icon)
    lib.showTextUI(text, {
        position = 'right-center',
        icon = icon or 'truck',
        style = {
            borderRadius = 8,
            backgroundColor = '#161a1d',
            color = '#e5e7eb'
        }
    })
end

-- job check
local jobOK = false
local function refreshJob()
    local pd = ESX.GetPlayerData and ESX.GetPlayerData() or ESX.PlayerData
    local name = pd and pd.job and pd.job.name
    jobOK = name == Config.RequiredJob
end

local function clearDepotBlip()
    if state.depotBlip then
        RemoveBlip(state.depotBlip)
        state.depotBlip = nil
    end
end

local function createDepotBlip()
    clearDepotBlip()
    local c = Config.Depot
    local blip = AddBlipForCoord(c.coords.x, c.coords.y, c.coords.z)
    SetBlipSprite(blip, c.blip.sprite or 478)
    SetBlipColour(blip, c.blip.color or 5)
    SetBlipScale(blip, c.blip.scale or 0.9)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, false)
    SetBlipPriority(blip, 10)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('GoPostal Depot')
    EndTextCommandSetBlipName(blip)
    state.depotBlip = blip
end

CreateThread(function()
    refreshJob()
    if jobOK then createDepotBlip() else clearDepotBlip() end
end)

AddEventHandler('esx:playerLoaded', function()
    refreshJob()
    if jobOK then createDepotBlip() else clearDepotBlip() end
end)

RegisterNetEvent('esx:setJob', function()
    refreshJob()
    if jobOK then createDepotBlip() else clearDepotBlip() end
end)

-- depot menu
local function openDepotMenu()
    if not jobOK then
        notify('Alleen personeel kan dit gebruiken')
        return
    end
    local opts = {}
    if not state.active then
        opts[#opts+1] = {
            title = 'Start route',
            description = 'Pak pakketten en begin',
            onSelect = function()
                TriggerServerEvent('deliveryjob:start')
            end
        }
        opts[#opts+1] = {
            title = 'Uitleg',
            description = 'Hoe werkt deze job',
            onSelect = function()
                lib.registerContext({
                    id = 'deliveryjob_info',
                    title = 'GoPostal - Uitleg',
                    options = {
                        { title = '1) In dienst', description = 'Praat met postbezorger bij GoPostal' },
                        { title = '2) Start route', description = 'Kies start, pak het pakket achter in het busje (achterdeur) en lever het adres' },
                        { title = '3) Afronden', description = 'Keer terug en verwerk/afronden voor bonus' }
                    }
                })
                lib.showContext('deliveryjob_info')
            end
        }
    else
        opts[#opts+1] = {
            title = 'Afronden',
            description = 'Bekijk bezorging en bevestig afronden',
            onSelect = function()
                openFinishConfirm()
            end
        }
        opts[#opts+1] = {
            title = 'Stoppen',
            description = 'Annuleer huidige route',
            onSelect = function()
                TriggerServerEvent('deliveryjob:cancel')
            end
        }
    end

    lib.registerContext({
        id = 'deliveryjob_menu',
        title = 'Pakket Depot',
        options = opts
    })
    lib.showContext('deliveryjob_menu')
end

-- bevestiging afronden + overzicht
local function openFinishConfirm()
    local delivered = state.delivered or 0
    local total = (state.route and #state.route) or (Config and Config.DeliveriesPerRoute) or 20
    local opts = {
        { title = ('Bezorgd: %s / %s'):format(delivered, total), description = 'Overzicht van je route' }
    }
    opts[#opts+1] = {
        title = 'Weet je het zeker? (afronden en uitbetalen)'
        , description = 'Je krijgt je geld voor bezorgde boxen. De route wordt beëindigd!'
        , onSelect = function()
            TriggerServerEvent('deliveryjob:finish')
        end
    }
    lib.registerContext({ id = 'deliveryjob_finish', title = 'Afronden', options = opts })
    lib.showContext('deliveryjob_finish')
end

-- ped + ox_target bij GoPostal
local function setupDepotPed()
    if state.depotPed and DoesEntityExist(state.depotPed) then return end
    local model = joaat('s_m_m_postal_01')
    if not lib.requestModel(model, 5000) then return end
    local p = Config.Depot.pedSpawn
    local ped = CreatePed(4, model, p.x, p.y, p.z - 1.0, p.w, false, false)
    SetEntityHeading(ped, p.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    state.depotPed = ped
    SetModelAsNoLongerNeeded(model)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'In dienst / Start',
            icon = 'fa-solid fa-truck-fast',
            onSelect = function()
                openDepotMenu()
            end,
            canInteract = function(entity, distance, coords, name)
                return jobOK and not state.active
            end
        },
        {
            label = 'Afronden',
            icon = 'fa-solid fa-user-minus',
            onSelect = function()
                openFinishConfirm()
            end,
            canInteract = function(entity, distance, coords, name)
                return jobOK and state.active
            end
        },
        {
            label = 'Uitleg',
            icon = 'fa-solid fa-info',
            onSelect = function()
                lib.registerContext({
                    id = 'deliveryjob_info',
                    title = 'GoPostal - Uitleg',
                    options = {
                        { title = '1) In dienst', description = 'Praat met postbezorger bij GoPostal' },
                        { title = '2) Start route', description = 'Kies start, pak het pakket achter in het busje (achterdeur) en lever het adres' },
                        { title = '3) Afronden', description = 'Keer terug en verwerk/afronden' }
                    }
                })
                lib.showContext('deliveryjob_info')
            end
        }
    })
end

CreateThread(function()
    setupDepotPed()
end)

local function clearDeliveryBlip()
    if state.blip then
        RemoveBlip(state.blip)
        state.blip = nil
    end
    if state.targetPoint then
        state.targetPoint:remove()
        state.targetPoint = nil
    end
    if state.dropPed and DoesEntityExist(state.dropPed) then
        DeleteEntity(state.dropPed)
        state.dropPed = nil
    end
end

local function setDeliveryTarget(pos)
    clearDeliveryBlip()
    -- Ondersteun zowel vec3 als { name, pos = vec3 }
    local src = (type(pos) == 'table' and pos.pos and pos.pos.x) and pos.pos or pos
    -- Zoek een veilige buitenpositie in de buurt en corrigeer hoogte
    local base = vector3(src.x, src.y, src.z)
    local okSafe, safe = GetSafeCoordForPed(base.x, base.y, base.z + 2.0, true, 16)
    if okSafe and safe then
        base = safe
    end
    local okG, gz = GetGroundZFor_3dCoord(base.x, base.y, base.z + 2.0, true)
    if okG and gz then
        base = vector3(base.x, base.y, gz)
    end

    state.blip = AddBlipForCoord(base.x, base.y, base.z)
    SetBlipSprite(state.blip, 1)
    SetBlipColour(state.blip, 5)
    SetBlipScale(state.blip, 0.9)
    SetBlipPriority(state.blip, 10)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Levering')
    EndTextCommandSetBlipName(state.blip)
    SetBlipRoute(state.blip, true)

    state.targetPoint = lib.points.new(base, Config.DeliverRadius + 2.0, {
        onEnter = function()
            -- tekst via nearby
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(self)
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local target = vector3(base.x, base.y, base.z)
            local nearTarget = #(pedPos - target) < (Config.DeliverRadius + 1.5)
            local dropPos
            if state.veh and DoesEntityExist(state.veh) then
                dropPos = GetOffsetFromEntityInWorldCoords(state.veh, 0.0, -2.6, 0.2)
            end
            if nearTarget then
                if not state.carrying then
                    showUI('Pak eerst een box uit het busje', 'box')
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
    })
    -- automatische spawn voor NPC die de box afneemt - config gerelateerd maar vindt een goede spot
    local function findDropPedSpawn(base)
        local function goodSpot(x, y, z)
            if IsPointInWater(x, y, z) then return false end
            if GetInteriorAtCoords(x, y, z) ~= 0 then return false end
            local occupied = IsPositionOccupied(x, y, z, 0.6, false, true, true, false, false, 0, false)
            if occupied then return false end
            return true
        end

        local radii = { 2.5, 3.5, 5.0, 7.0 }
        for rIdx = 1, #radii do
            local r = radii[rIdx]
            for deg = 0, 315, 45 do
                local rad = math.rad(deg)
                local tryX = base.x + math.cos(rad) * r
                local tryY = base.y + math.sin(rad) * r
                local tryZ = base.z + 2.0
                local statuss, gz = GetGroundZFor_3dCoord(tryX, tryY, tryZ, true)
                if statuss and gz and goodSpot(tryX, tryY, gz) then
                    return vector3(tryX, tryY, gz)
                end
            end
        end

        -- Fallback: in het geval ground direct onder het basispunt
        local statuss, gz = GetGroundZFor_3dCoord(base.x, base.y, base.z + 2.0, true)
        if statuss and gz then
            return vector3(base.x, base.y, gz)
        end
        return base
    end

    -- spawn een NPC die de box aanneemt bij het afleverpunt
    local pedModel = joaat('a_m_y_business_01')
    if lib.requestModel(pedModel, 5000) then
        local spawnPos = findDropPedSpawn(base)
        local ped = CreatePed(4, pedModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, false, false)
        local heading = GetHeadingFromVector_2d(base.x - spawnPos.x, base.y - spawnPos.y)
        SetEntityHeading(ped, heading)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        state.dropPed = ped
        SetModelAsNoLongerNeeded(pedModel)

        exports.ox_target:addLocalEntity(ped, {
            {
                label = 'Geef box af',
                icon = 'fa-solid fa-box',
                distance = 2.2,
                onSelect = function()
                    if not state.carrying then
                        notify('Pak eerst een box uit het busje')
                        return
                    end
                    local statuss = lib.progressBar({
                        duration = 2000,
                        label = 'Box overhandigen...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true }
                    })
                    if statuss then
                        local ped2 = PlayerPedId()
                        ClearPedTasks(ped2)
                        if state.carryProp and DoesEntityExist(state.carryProp) then DeleteObject(state.carryProp) end
                        state.carryProp = nil
                        state.carrying = false
                        -- sluit achterdeuren na afleveren zodat ze niet open blijven
                        if state.veh and DoesEntityExist(state.veh) then
                            SetVehicleDoorShut(state.veh, 2, false)
                            SetVehicleDoorShut(state.veh, 3, false)
                        end
                        TriggerServerEvent('deliveryjob:delivered', state.idx)
                    end
                end,
                canInteract = function(entity, distance, coords, name)
                    return state.active == true
                end
            }
        })
    end
end

local function spawnVehicle()
    local model = joaat(Config.VehicleModel)
    if not lib.requestModel(model, 5000) then return end

    local free = {}
    for i=1, #Config.VehicleSpawns do
        local sp = Config.VehicleSpawns[i]
        local veh = GetClosestVehicle(sp.x, sp.y, sp.z, 3.0, 0, 70)
        if veh == 0 or not DoesEntityExist(veh) then
            free[#free+1] = sp
        end
    end

    if #free == 0 then
        notify('Geen vrije parkeerplek, alle plaatsen bezet')
        SetModelAsNoLongerNeeded(model)
        return
    end

    local pos = free[math.random(1, #free)]
    local veh = CreateVehicle(model, pos.x, pos.y, pos.z, pos.w, true, false)
    SetVehicleOnGroundProperly(veh)
    -- zet speler meteen in bestuurdersstoel
    local ped = PlayerPedId()
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    state.vehNetId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('deliveryjob:setVeh', state.vehNetId)
    -- voorbeeld: lock + keys via externe resource
    -- SetVehicleDoorsLocked(veh, 2)
    -- keys (voorbeeld) . Vervang met jullie eigen locks/keys.
    -- TriggerEvent('srp_lock:giveKeys', NetworkGetNetworkIdFromEntity(veh))
    -- of bijvoorbeeld:
    -- TriggerEvent('vehiclekeys:client:AddKeys', GetVehicleNumberPlateText(veh))

    state.veh = veh
    SetModelAsNoLongerNeeded(model)
end

local function clearVanBoxes()
    if state.vanBoxes and #state.vanBoxes > 0 then
        for i = 1, #state.vanBoxes do
            local obj = state.vanBoxes[i]
            if obj and DoesEntityExist(obj) then DeleteObject(obj) end
        end
    end
    state.vanBoxes = {}
end

local function spawnVanBoxes(count)
    clearVanBoxes()
    if not state.veh or count <= 0 then return end
    local maxBoxes = math.min(count, #Config.BoxOffsets)
    local model = joaat(Config.BoxModel)
    if not lib.requestModel(model, 5000) then return end
    for i = 1, maxBoxes do
        local offset = Config.BoxOffsets[i]
        local obj = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityCollision(obj, true, true)
        -- attach aan voertuig zodat dozen in de auto blijven - in het geval als er ox_target gebruikt zal worden ipv ui :O
        local bone = GetEntityBoneIndexByName(state.veh, 'chassis')
        if bone == -1 then bone = 0 end
        AttachEntityToEntity(obj, state.veh, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
        table.insert(state.vanBoxes, obj)
    end
end

local function removeVanBoxEntity(entity)
    if not state.vanBoxes then return end
    for i = 1, #state.vanBoxes do
        local obj = state.vanBoxes[i]
        if obj == entity then
            table.remove(state.vanBoxes, i)
            break
        end
    end
end

local function getNearestVanBox(maxDist)
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local best, bestDist
    for i = 1, #state.vanBoxes do
        local obj = state.vanBoxes[i]
        if obj and DoesEntityExist(obj) then
            local d = #(GetEntityCoords(obj) - p)
            if not bestDist or d < bestDist then
                best = obj
                bestDist = d
            end
        end
    end
    if best and (not maxDist or bestDist <= maxDist) then return best end
    return nil
end

RegisterNetEvent('deliveryjob:boxOk', function()
    if state.carrying then return end
    local ped = PlayerPedId()
    if not lib.requestAnimDict('anim@heists@box_carry@', 5000) then return end
    local model = joaat(Config.BoxModel)
    if not lib.requestModel(model, 5000) then return end
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, -0.05, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 51, 0, false, false, false)
    state.carryProp = prop
    state.carrying = true
    if state._pendingPickupEntity and DoesEntityExist(state._pendingPickupEntity) then
        DeleteObject(state._pendingPickupEntity)
        removeVanBoxEntity(state._pendingPickupEntity)
    else
        local nearest = getNearestVanBox(5.0)
        if nearest then
            DeleteObject(nearest)
            removeVanBoxEntity(nearest)
        end
    end
    state._pendingPickupEntity = nil
end)

-- server: route ontvangen
RegisterNetEvent('deliveryjob:route', function(route)
    state.active = true
    state.route = route
    state.idx = 1
    state.delivered = 0
    -- notify('Pak het pakket achter in het busje (achterdeur) t en ga leveren')
    state.done = false
    spawnVehicle()
    spawnVanBoxes(#route)
    -- achterdeur target verwijderd: geen ox_target op voertuig voor deuren
    setDeliveryTarget(route[state.idx])
end)

-- achterzijde busje: oppakken via [E]
CreateThread(function()
    while true do
        Wait(0)
        if state.active and state.veh and DoesEntityExist(state.veh) then
            local ped = PlayerPedId()
            local backPos = GetOffsetFromEntityInWorldCoords(state.veh, 0.0, -2.6, 0.2)
            local dist = #(GetEntityCoords(ped) - backPos)
            local nearDest = false
            if state.route and state.route[state.idx] then
                local tgt = state.route[state.idx]
                local tgtPos = (type(tgt) == 'table' and tgt.pos and tgt.pos.x) and tgt.pos or tgt
                nearDest = #(GetEntityCoords(ped) - vector3(tgtPos.x, tgtPos.y, tgtPos.z)) <= 30.0
            end
            if dist < 2.2 and nearDest and not state.carrying and state.vanBoxes and #state.vanBoxes > 0 then
                showUI('[E] Pak box uit busje', 'box')
                if IsControlJustReleased(0, 38) then
                    local nearest = getNearestVanBox(4.0)
                    state._pendingPickupEntity = nearest
                    TriggerServerEvent('deliveryjob:pickupBox', state.vehNetId)
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        else
            Wait(250)
        end
    end
end)

-- samenvatting bij uitdienst
RegisterNetEvent('deliveryjob:summary', function(drops, total)
    state.lastSummaryDrops = drops or 0
    notify(('Dienst afgerond. Bezorgd: %s | Uitbetaling: $%s (item)'):format(drops, total))
end)

-- outfit bij in dienst
RegisterNetEvent('deliveryjob:dutyOutfit', function(maleJson, femaleJson)
    local ped = PlayerPedId()
    local isMale = GetEntityModel(ped) == joaat('mp_m_freemode_01')
    -- vorige outfit opslaan
    if pcall(function() return exports['esx_appearance'] ~= nil end) then
        local statuss, prev = pcall(function() return exports['esx_appearance']:getPedAppearance(ped) end)
        if statuss then state.prevAppearance = prev end
    else
        TriggerEvent('skinchanger:getSkin', function(skin)
            state.prevAppearance = skin
        end)
    end
    local chosen = isMale and maleJson or femaleJson
    local clothes
    if chosen and chosen ~= '' then
        local statuss, decoded = pcall(function() return json.decode(chosen) end)
        if statuss then clothes = decoded end
    end

    if clothes then
        if pcall(function() return exports['esx_appearance'] ~= nil end) then
            exports['esx_appearance']:setPedAppearance(ped, clothes)
        else
            TriggerEvent('skinchanger:getSkin', function(skin)
                TriggerEvent('skinchanger:loadClothes', skin, clothes)
            end)
        end
    else
        local fallback = {
            tshirt_1 = 15, tshirt_2 = 0,
            torso_1 = 65, torso_2 = 0,
            pants_1 = 38, pants_2 = 0,
            shoes_1 = 12, shoes_2 = 0,
            arms = 11
        }
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent('skinchanger:loadClothes', skin, fallback)
        end)
    end
end)

-- server: volgende punt
RegisterNetEvent('deliveryjob:next', function(nextIdx)
    state.idx = nextIdx
    state.delivered = (state.delivered or 0) + 1
    setDeliveryTarget(state.route[state.idx])
    notify('Volgende adres laden...')
end)

-- server: alles geleverd
RegisterNetEvent('deliveryjob:all_delivered', function()
    clearDeliveryBlip()
    state.done = true
    state.delivered = state.route and #state.route or state.delivered
    notify('Ga terug naar depot om af te ronden')
end)

-- server: finish goedgekeurd
RegisterNetEvent('deliveryjob:finished', function()
    state.active = false
    state.route = nil
    state.idx = 0
    state.done = false
    state.delivered = 0
    clearDeliveryBlip()
    if state.veh and DoesEntityExist(state.veh) then
        DeleteEntity(state.veh)
        state.veh = nil
    end
    if state.carryProp and DoesEntityExist(state.carryProp) then DeleteObject(state.carryProp) end
    state.carryProp = nil
    state.carrying = false
    clearVanBoxes()
    -- outfit terugzetten
    local ped = PlayerPedId()
    if state.prevAppearance then
        if pcall(function() return exports['esx_appearance'] ~= nil end) then
            exports['esx_appearance']:setPedAppearance(ped, state.prevAppearance)
        else
            TriggerEvent('skinchanger:loadSkin', state.prevAppearance)
        end
        state.prevAppearance = nil
    end
    if (state.lastSummaryDrops or 0) <= 0 then
        notify('Bezorging gestaakt')
    else
        notify('Route klaar, netjes gedaan')
    end
    state.lastSummaryDrops = 0
end)

-- server: cancel
RegisterNetEvent('deliveryjob:cancelled', function()
    state.active = false
    state.route = nil
    state.idx = 0
    state.done = false
    state.delivered = 0
    clearDeliveryBlip()
    if state.veh and DoesEntityExist(state.veh) then
        DeleteEntity(state.veh)
        state.veh = nil
    end
    if state.carryProp and DoesEntityExist(state.carryProp) then DeleteObject(state.carryProp) end
    state.carryProp = nil
    state.carrying = false
    clearVanBoxes()
    -- outfit terugzetten
    local ped = PlayerPedId()
    if state.prevAppearance then
        if pcall(function() return exports['esx_appearance'] ~= nil end) then
            exports['esx_appearance']:setPedAppearance(ped, state.prevAppearance)
        else
            TriggerEvent('skinchanger:loadSkin', state.prevAppearance)
        end
        state.prevAppearance = nil
    end
    notify('Route gestopt')
end)