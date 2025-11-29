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
    lastSummaryDrops = 0,
    signatures = {},
    signatureOpen = false,
    notHome = false,
    notHomeChecked = false,
    backPos = nil,
    pickupActive = false,
    pickupObj = nil,
    pickupNpc = nil,
    pickupSpawned = false,
    prePickupNotified = false,
    pickupTakenNotified = false,
    sigRequired = false
}
local function notify(msg)
    lib.notify({ title = 'Pakket', description = msg, type = 'inform' })
end

-- check of achterdeuren open staan minimaal een deur als je ui E vervangt met ox_target
-- local function rearDoorsOpen()
--     if not (state.veh and DoesEntityExist(state.veh)) then return false end
--     local left = GetVehicleDoorAngleRatio(state.veh, 2) or 0.0
--     local right = GetVehicleDoorAngleRatio(state.veh, 3) or 0.0
--     return (left > 0.1) or (right > 0.1)
-- end

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

-- pickup animatie helpers
local function playPickupAnim(ped)
    local variants = {
        { dict = 'anim@mp_snowball', name = 'pickup_snowball', dur = 1500 },
        { dict = 'anim@mp@pick_up@', name = 'pick_up', dur = 1500 },
        { dict = 'random@domestic', name = 'pickup_low', dur = 1500 }
    }
    for i = 1, #variants do
        local v = variants[i]
        if lib.requestAnimDict(v.dict, 3000) then
            TaskPlayAnim(ped, v.dict, v.name, 4.0, -4.0, v.dur, 0, 0, false, false, false)
            return true
        end
    end
    return false
end

-- forward declare clearHands so earlier functions can reference it
local clearHands

-- handtekening pad
local sigPad = { active = false, points = {}, hasInk = false, rect = { x = 0.5, y = 0.75, w = 0.36, h = 0.22 } }
local function inRect(mx, my, r)
    return mx > (r.x - r.w/2) and mx < (r.x + r.w/2) and my > (r.y - r.h/2) and my < (r.y + r.h/2)
end
local function drawSigPad()
    local r = sigPad.rect
    DrawRect(r.x, r.y, r.w, r.h, 21, 25, 29, 185)
    -- rand
    DrawRect(r.x, r.y - r.h/2, r.w, 0.003, 245, 191, 36, 200)
    DrawRect(r.x, r.y + r.h/2, r.w, 0.003, 245, 191, 36, 200)
    DrawRect(r.x - r.w/2, r.y, 0.003, r.h, 245, 191, 36, 200)
    DrawRect(r.x + r.w/2, r.y, 0.003, r.h, 245, 191, 36, 200)
    -- streken tekenen
    for i = 2, #sigPad.points do
        local a = sigPad.points[i-1]
        local b = sigPad.points[i]
        if not b.new and not a.new then
            local cx = (a.x + b.x) / 2.0
            local cy = (a.y + b.y) / 2.0
            DrawRect(cx, cy, 0.0028, 0.0028, 251, 191, 36, 220)
        end
    end
end
local function openSignaturePad(address)
    if sigPad.active then return end
    sigPad.active = true
    sigPad.points = {}
    sigPad.hasInk = false
    state.signatureOpen = true
    lib.showTextUI(('Handtekening voor %s | Enter bevestigen, G wissen, Backspace annuleren'):format(address or 'Adres'), { position = 'right-center', icon = 'pen', style = { borderRadius = 8, backgroundColor = '#161a1d', color = '#e5e7eb' } })
    CreateThread(function()
        while sigPad.active do
            Wait(0)
            SetMouseCursorActiveThisFrame()
            drawSigPad()
            -- input
            local mx = GetControlNormal(0, 239)
            local my = GetControlNormal(0, 240)
            local inPad = inRect(mx, my, sigPad.rect)
            DisableControlAction(0, 24, true)   -- attack
            DisableControlAction(0, 25, true)   -- aim
            DisableControlAction(0, 1, true)    -- look x
            DisableControlAction(0, 2, true)    -- look y
            if inPad then
                if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 237) then
                    sigPad.points[#sigPad.points+1] = { x = mx, y = my, new = false }
                    sigPad.hasInk = true
                else
                    sigPad.points[#sigPad.points+1] = { x = mx, y = my, new = true }
                end
            end
            -- bevestigen
            if IsControlJustReleased(0, 18) then -- Enter
                if sigPad.hasInk then
                    state.signatures[state.idx] = { points = sigPad.points, ts = GetGameTimer() }
                    sigPad.active = false
                    lib.hideTextUI()
                    state.signatureOpen = false
                    -- na handtekening direct afleveren
                    local statuss = lib.progressBar({ duration = 1600, label = 'Bevestigen...', useWhileDead = false, canCancel = false, disable = { car = true, move = true } })
                    if statuss and state.carrying then
                        clearHands(PlayerPedId())
                        state.carrying = false
                        if state.veh and DoesEntityExist(state.veh) then
                            SetVehicleDoorShut(state.veh, 2, false)
                            SetVehicleDoorShut(state.veh, 3, false)
                        end
                        TriggerServerEvent('deliveryjob:delivered', state.idx)
                    end
                else
                    lib.notify({ title = 'Pakket', description = 'Zet eerst je handtekening', type = 'error' })
                end
            end
            -- wissen
            if IsControlJustReleased(0, 47) then -- G
                sigPad.points = {}
                sigPad.hasInk = false
            end
            -- annuleren
            if IsControlJustReleased(0, 194) then -- Backspace
                sigPad.active = false
                lib.hideTextUI()
                state.signatureOpen = false
            end
        end
    end)
end

local function requiresSignature()
    local entry = state.route and state.route[state.idx]
    if type(entry) == 'table' and entry.signature ~= nil then return entry.signature end
    return math.random() < (Config.SignatureChance or 0.0)
end

local function computeBackPos(entry)
    if type(entry) == 'table' then
        if entry.nh and #entry.nh > 0 then
            local pick = entry.nh[math.random(1, #entry.nh)]
            if pick and pick.x then return pick end
        end
        if entry.back and entry.back.x then return entry.back end
    end
    local p = (type(entry) == 'table' and entry.pos and entry.pos.x) and entry.pos or entry
    local guess = vector3(p.x, p.y - 4.5, p.z)
    local okG, gz = GetGroundZFor_3dCoord(guess.x, guess.y, guess.z + 2.0, true)
    if okG and gz then return vector3(guess.x, guess.y, gz) end
    return guess
end

-- realistische pickup anim
local function doVanPickupSequence(veh)
    local ped = PlayerPedId()
    if veh and DoesEntityExist(veh) then
        -- open achterdeuren indien nodig
        SetVehicleDoorOpen(veh, 2, false, false)
        SetVehicleDoorOpen(veh, 3, false, false)
        -- kleine stap naar binnen voor visuele geloofwaardigheid
        local reachPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -1.1, 0.0)
        TaskGoStraightToCoord(ped, reachPos.x, reachPos.y, reachPos.z, 1.0, 700, GetEntityHeading(veh), 0.5)
        Wait(500)
    end
    playPickupAnim(ped)
    Wait(1200)
    return true
end

-- Na het oppakken een halve meter achteruit stappen
local function stepBackFromVanAfterPickup()
    if state.veh and DoesEntityExist(state.veh) then
        local backPos = GetOffsetFromEntityInWorldCoords(state.veh, 0.0, -2.2, 0.0)
        TaskGoStraightToCoord(PlayerPedId(), backPos.x, backPos.y, backPos.z, 1.0, 800, GetEntityHeading(state.veh), 0.0)
    end
end

-- hand object cleanup helper zorgt dat er niks meer in je handen zit
function clearHands(ped)
    ClearPedTasks(ped)
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    if state.carryProp and DoesEntityExist(state.carryProp) then DeleteObject(state.carryProp) end
    state.carryProp = nil
    local objs = GetGamePool('CObject')
    local rightPos = GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0)
    local leftPos = GetPedBoneCoords(ped, 60309, 0.0, 0.0, 0.0)
    for i = 1, #objs do
        local obj = objs[i]
        if IsEntityAttachedToEntity(obj, ped) then
            local oc = GetEntityCoords(obj)
            if #(oc - rightPos) < 1.5 or #(oc - leftPos) < 1.5 then
                DeleteObject(obj)
            end
        end
    end
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

RegisterNetEvent('esx:playerLoaded', function()
    -- Wordt vanaf de server getriggerd; update blip op basis van job
    refreshJob()
    if jobOK then createDepotBlip() else clearDepotBlip() end
end)

RegisterNetEvent('esx:setJob', function()
    -- ESX job wissel: update blip
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

-- cleanup van huidige doel en entiteiten
local function clearCurrentTarget()
    if state.targetPoint and state.targetPoint.remove then
        pcall(function() state.targetPoint:remove() end)
    end
    state.targetPoint = nil
    if state.backTargetPoint and state.backTargetPoint.remove then
        pcall(function() state.backTargetPoint:remove() end)
    end
    state.backTargetPoint = nil
    if state.dropPed and DoesEntityExist(state.dropPed) then
        DeleteEntity(state.dropPed)
    end
    state.dropPed = nil
    if state.backBlip then
        RemoveBlip(state.backBlip)
        state.backBlip = nil
    end
    state.notHome = false
    state.notHomeChecked = false
    state.backPos = nil
    state.sigRequired = false
    state.pickupSpawned = false
    state.prePickupNotified = false
    state.pickupTakenNotified = false
    if state.pickupNpc and DoesEntityExist(state.pickupNpc) then
        DeleteEntity(state.pickupNpc)
    end
    state.pickupNpc = nil
end

-- zoek een veilige spawnplek voor de drop NPC
local function findDropPedSpawn(base)
    local function goodSpot(x, y, z)
        local hasWater, waterZ = GetWaterHeight(x, y, z + 1.0)
        if hasWater and waterZ and (waterZ > (z - 0.5)) then return false end
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

    -- fallback als de grond direct onder het basispunt ligt
    local statuss, gz = GetGroundZFor_3dCoord(base.x, base.y, base.z + 2.0, true)
    if statuss and gz then
        return vector3(base.x, base.y, gz)
    end
    return base
end

-- forward declaration so closures capture the local symbol
local spawnPickupAtAddress

-- pickup pakket bij adres via ox_target op NPC die het vasthoudt
spawnPickupAtAddress = function(entry)
    if not entry or not entry.pos then return end
    if not entry.pickup then return end
    local p = entry.front and entry.front or entry.pos
    local pedModel = joaat('a_m_m_business_01')
    if not lib.requestModel(pedModel, 5000) then return end
    local ped = CreatePed(4, pedModel, p.x, p.y, p.z, 0.0, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    state.pickupNpc = ped
    local model = joaat(Config.BoxModel)
    if not lib.requestModel(model, 5000) then return end
    local held = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(held, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, -0.05, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Pak pakket in ontvangst',
            icon = 'fa-solid fa-box',
            distance = 2.2,
            onSelect = function()
                if state.carrying then return end
                playPickupAnim(PlayerPedId())
                local ok = lib.progressBar({ duration = 3200, label = 'Pakket ophalen...', useWhileDead = false, canCancel = true, disable = { move = true, car = true } })
                ClearPedTasks(PlayerPedId())
                if ok then
                    local pedPlayer = PlayerPedId()
                    if not lib.requestAnimDict('anim@heists@box_carry@', 3000) then return end
                    local m = joaat(Config.BoxModel)
                    if not lib.requestModel(m, 3000) then return end
                    local prop = CreateObject(m, 0.0, 0.0, 0.0, true, true, false)
                    AttachEntityToEntity(prop, pedPlayer, GetPedBoneIndex(pedPlayer, 28422), 0.0, 0.0, -0.05, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
                    TaskPlayAnim(pedPlayer, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 51, 0, false, false, false)
                    state.carryProp = prop
                    state.carrying = true
                    state.pickupActive = true
                    TriggerServerEvent('deliveryjob:pickupNpc')
                    if state.pickupNpc and DoesEntityExist(state.pickupNpc) then
                        DeleteEntity(state.pickupNpc)
                        state.pickupNpc = nil
                    end
                    if DoesEntityExist(held) then DeleteObject(held) end
                    if not state.pickupTakenNotified then
                        lib.notify({ title = 'Pakket', description = (Config.Texts.PickupTaken or 'Pakket opgehaald — laad het in de bus'), type = 'inform' })
                        state.pickupTakenNotified = true
                    end
                end
            end,
            canInteract = function()
                return state.active == true
            end
        }
    })
end

local function setDeliveryTarget(pos)
    clearDeliveryBlip()
    clearCurrentTarget()
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
            -- bij aankomst scheiden we pickup en bezorging
            local entry = state.route and state.route[state.idx]
            local isPickup = (type(entry) == 'table' and entry.pickup == true)
            if isPickup then
                local addrName = (type(entry) == 'table' and entry.name) or 'Adres'
                if not state.prePickupNotified then
                    lib.notify({ title = 'Pakket', description = Config.Texts.PickupReady or 'Pickup op locatie', type = 'inform' })
                end
                if not state.pickupSpawned then
                    spawnPickupAtAddress(entry)
                    state.pickupSpawned = true
                end
                -- geen npc en geen niet-thuis bij pickup
                state.notHome = false
                state.notHomeChecked = true
                return
            end
            if not state.notHomeChecked then
                local chance = (Config.NotHomeChance or 0.0)
                state.notHome = (math.random() < chance)
                state.notHomeChecked = true
                if state.notHome then
                    local addrName = (type(entry) == 'table' and entry.name) or 'Adres'
                    lib.notify({ title = 'Pakket', description = Config.Texts.NotHome or 'Niemand thuis', type = 'inform' })
                    showUI('Bewoner niet thuis — volg de blauwe marker', 'house')
                    CreateThread(function()
                        Wait(2500)
                        lib.hideTextUI()
                    end)
                    local bp = computeBackPos(entry or base)
                    state.backPos = bp
                    state.backBlip = AddBlipForCoord(bp.x, bp.y, bp.z)
                    SetBlipSprite(state.backBlip, 1)
                    SetBlipColour(state.backBlip, 3)
                    SetBlipScale(state.backBlip, 0.85)
                    BeginTextCommandSetBlipName('STRING'); AddTextComponentString('Achtertuin'); EndTextCommandSetBlipName(state.backBlip)
                    local backPoint = lib.points.new(bp, Config.BackDropRadius or 3.5, {
                        onEnter = function() end,
                        onExit = function() lib.hideTextUI() end,
                        nearby = function()
                            if state.carrying then
                                -- blauw marker tonen op drop plek
                                DrawMarker(2, bp.x, bp.y, bp.z + 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.32, 0.32, 0.32, Config.DropMarker.r, Config.DropMarker.g, Config.DropMarker.b, 155, false, true, 2, false, nil, nil, false)
                                showUI('[E] Leg pakket in de tuin', 'box')
                                if IsControlJustReleased(0, 38) then
                                    if lib.requestAnimDict('amb@medic@standing@kneel@enter', 2000) then
                                        TaskPlayAnim(PlayerPedId(), 'amb@medic@standing@kneel@enter', 'enter', 4.0, -4.0, 1200, 0, 0, false, false, false)
                                    end
                                    local ok = lib.progressBar({ duration = 3800, label = 'Pakket neerleggen...', useWhileDead = false, canCancel = true, disable = { move = true, car = true } })
                                    ClearPedTasks(PlayerPedId())
                                    if ok then
                                        clearHands(PlayerPedId())
                                        state.carrying = false
                                        showUI('Pakket neergelegd — bezorging geregistreerd', 'check')
                                        CreateThread(function()
                                            Wait(2500)
                                            lib.hideTextUI()
                                        end)
                                        lib.notify({ title = 'Pakket', description = 'Pakket neergelegd — bezorging geregistreerd', type = 'success' })
                                        TriggerServerEvent('deliveryjob:delivered', state.idx)
                                    end
                                    lib.hideTextUI()
                                end
                            else
                                showUI('Pak eerst een box uit het busje', 'box')
                            end
                        end
                    })
                    state.backTargetPoint = backPoint
                    -- front marker weghalen zodra niet-thuis actief is
                    if state.targetPoint and state.targetPoint.remove then pcall(function() state.targetPoint:remove() end) end
                    state.targetPoint = nil
                    return
                end
                -- bezorging met npc
                local addrName = (type(entry) == 'table' and entry.name) or 'Adres'
                local preSig = (type(entry) == 'table' and entry.signature ~= nil) and entry.signature or (math.random() < (Config.SignatureChance or 0.0))
                state.sigRequired = preSig
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
                                local needSig = (state.sigRequired ~= nil) and state.sigRequired or requiresSignature()
                                if needSig and not (state.signatures[state.idx]) then
                                    lib.notify({ title = 'Pakket', description = Config.Texts.NeedSignature or 'Handtekening nodig', type = 'inform' })
                                    local e2 = state.route and state.route[state.idx]
                                    local addrName = type(e2) == 'table' and e2.name or 'Adres'
                                    openSignaturePad(addrName)
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
                                    clearHands(ped2)
                                    state.carrying = false
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
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(self)
            local ped = PlayerPedId()
            local pedPos = GetEntityCoords(ped)
            local target = vector3(base.x, base.y, base.z)
            local nearTarget = #(pedPos - target) < (Config.DeliverRadius + 1.5)
            -- vroege pickup notify als je in de buurt bent
            local entry = state.route and state.route[state.idx]
            local isPickup = (type(entry) == 'table' and entry.pickup == true)
            if isPickup and (not state.prePickupNotified) then
                local dist = #(pedPos - target)
                if dist <= 50.0 then
                    lib.notify({ title = 'Pakket', description = Config.Texts.PickupReady or 'Pickup op locatie', type = 'inform' })
                    state.prePickupNotified = true
                end
            end
            local dropPos
            if state.veh and DoesEntityExist(state.veh) then
                dropPos = GetOffsetFromEntityInWorldCoords(state.veh, 0.0, -2.6, 0.2)
            end
            if nearTarget then
                if not state.carrying then
                    -- als we vlak bij de bus staan en er zijn dozen, laat de E-prompt het doen
                    local busClose = false
                    if dropPos and state.vanBoxes and #state.vanBoxes > 0 then
                        busClose = (#(pedPos - dropPos) < 2.4)
                    end
                    if isPickup then
                        showUI('Gebruik target om het pakket op te halen', 'box')
                    elseif not busClose then
                        showUI('Pak eerst een box uit het busje', 'box')
                    end
                else
                    lib.hideTextUI()
                end
            else
                -- buiten doelgebied geen text ui van dit punt
                lib.hideTextUI()
            end
        end
    })
    -- helper findDropPedSpawn staat nu bovenaan
    -- npc spawn en niet-thuis worden in onEnter afgehandeld
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
    -- voorbeeld lock en keys via externe resource
    -- SetVehicleDoorsLocked(veh, 2)
    -- keys voorbeeld vervang met jullie eigen locks of keys
    -- voorbeeld event srp_lock giveKeys NetworkGetNetworkIdFromEntity veh
    -- of bijvoorbeeld
    -- voorbeeld event vehiclekeys client AddKeys GetVehicleNumberPlateText veh

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
    local desired = Config.VanBoxCount or count
    if not state.veh or (desired <= 0) then return end
    local maxBoxes = math.min(desired, #Config.BoxOffsets)
    local model = joaat(Config.BoxModel)
    if not lib.requestModel(model, 5000) then return end
    for i = 1, maxBoxes do
        local offset = Config.BoxOffsets[i]
        local obj = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityCollision(obj, true, true)
        -- we plakken de dozen aan het voertuig zodat ze in de auto blijven als je ox_target gebruikt in plaats van ui en zo
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

-- duplicate spawnPickupAtAddress removed (see top-level definition)

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
    -- stap terug voor een natuurlijk effect na oppakken
    stepBackFromVanAfterPickup()
end)

-- server route ontvangen
RegisterNetEvent('deliveryjob:route', function(route)
    state.active = true
    state.route = route
    state.idx = 1
    state.delivered = 0
    -- tip pak het pakket achter in het busje en ga leveren
    state.done = false
    spawnVehicle()
    spawnVanBoxes(#route)
    -- achterdeur target weg geen ox_target op voertuig voor deuren
    setDeliveryTarget(route[state.idx])
    -- pickup NPC spawnt bij aankomst op het adres (onEnter)
end)

-- achterkant van het busje oppakken met E
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
            local isPickup = (type(state.route and state.route[state.idx]) == 'table' and (state.route[state.idx].pickup == true))
            if dist < 2.2 and nearDest and not isPickup and not state.carrying and state.vanBoxes and #state.vanBoxes > 0 then
                if not state.vanUIShown then
                    showUI('[E] Pak box uit busje', 'box')
                    state.vanUIShown = true
                end
                if IsControlJustReleased(0, 38) then
                    local nearest = getNearestVanBox(4.0)
                    state._pendingPickupEntity = nearest
                    local ped = PlayerPedId()
                    -- realistische pickup deuren open naar binnen reiken anim en progressbalk
                    doVanPickupSequence(state.veh)
                    local ok = lib.progressBar({
                        duration = 2200,
                        label = 'Doos uit busje pakken...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true }
                    })
                    ClearPedTasks(ped)
                    if ok then
                        TriggerServerEvent('deliveryjob:pickupBox', state.vehNetId)
                    else
                        state._pendingPickupEntity = nil
                    end
                    if state.vanUIShown then
                        lib.hideTextUI()
                        state.vanUIShown = false
                    end
                end
            else
                if state.vanUIShown then
                    lib.hideTextUI()
                    state.vanUIShown = false
                end
            end
            -- stow opgehaald pakket in busje en afronden
            if dist < 2.2 and state.pickupActive and state.carrying then
                showUI('[E] Leg opgehaald pakket in busje', 'box')
                if IsControlJustReleased(0, 38) then
                    local ok2 = lib.progressBar({ duration = 3000, label = 'Pakket inladen...', useWhileDead = false, canCancel = true, disable = { move = true, car = true } })
                    if ok2 then
                        clearHands(PlayerPedId())
                        state.carrying = false
                        state.pickupActive = false
                        TriggerServerEvent('deliveryjob:collectedPickup', state.idx)
                    end
                    lib.hideTextUI()
                end
            end
        else
            Wait(250)
        end
    end
end)

-- samenvatting bij uitdienst
RegisterNetEvent('deliveryjob:summary', function(drops, total)
    state.lastSummaryDrops = drops or 0
    notify(('Dienst afgerond. Bezorgd: %s | Uitbetaling: $%s'):format(drops, total))
end)

-- outfit bij in dienst (met als voorbeeld esx_appearance)
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

-- server volgende punt
RegisterNetEvent('deliveryjob:next', function(nextIdx)
    state.idx = nextIdx
    state.delivered = (state.delivered or 0) + 1
    setDeliveryTarget(state.route[state.idx])
    notify('Volgende adres laden...')
    -- pickup NPC spawnt bij aankomst op het adres (onEnter)
end)

-- server alles geleverd
RegisterNetEvent('deliveryjob:all_delivered', function()
    clearDeliveryBlip()
    state.done = true
    state.delivered = state.route and #state.route or state.delivered
    notify('Ga terug naar depot om af te ronden')
end)

-- server finish goedgekeurd
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
    if state.pickupNpc and DoesEntityExist(state.pickupNpc) then DeleteEntity(state.pickupNpc) end
    state.pickupNpc = nil
    if state.carryProp and DoesEntityExist(state.carryProp) then DeleteObject(state.carryProp) end
    state.carryProp = nil
    state.carrying = false
    clearVanBoxes()
    if state.pickupObj and DoesEntityExist(state.pickupObj) then DeleteObject(state.pickupObj) end
    state.pickupObj = nil
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

-- server cancel
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
    if state.pickupNpc and DoesEntityExist(state.pickupNpc) then DeleteEntity(state.pickupNpc) end
    state.pickupNpc = nil
    if state.pickupObj and DoesEntityExist(state.pickupObj) then DeleteObject(state.pickupObj) end
    state.pickupObj = nil
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