local ESX = exports['es_extended']:getSharedObject()

local PlayerJobs = {}

-- kleine util
local function dist(a, b)
    return #(a - b)
end

local function getPointPos(p)
    if type(p) == 'vector3' or (p and p.x and p.y and p.z) then return p end
    if type(p) == 'table' and p.pos and p.pos.x then return p.pos end
    return p
end
local function isNearDepot(src)
    local ped = GetPlayerPed(src)
    local p = GetEntityCoords(ped)
    return dist(p, Config.Depot.coords) <= (Config.Depot.radius + 10.0)
end

local function makeRoute()
    local picks = {}
    for i = 1, #Config.DeliveryPoints do picks[i] = Config.DeliveryPoints[i] end
    for i = #picks, 2, -1 do
        local j = math.random(1, i)
        picks[i], picks[j] = picks[j], picks[i]
    end
    local count = math.min(Config.DeliveriesPerRoute, #picks)
    local route = {}
    for i = 1, count do route[i] = picks[i] end
    return route
end

-- haalt outfit uit SQL job_grades oxmysql
local function getJobOutfit(jobName, grade)
    local row
    if MySQL and MySQL.single then
        row = MySQL.single('SELECT skin_male, skin_female FROM job_grades WHERE job_name = ? AND grade = ?', {jobName, grade})
    else
        local ok, res = pcall(function()
            return exports.oxmysql:single('SELECT skin_male, skin_female FROM job_grades WHERE job_name = ? AND grade = ?', {jobName, grade})
        end)
        if ok then row = res end
    end
    if row then return row.skin_male, row.skin_female end
    return nil, nil
end

RegisterNetEvent('deliveryjob:start', function()
    local src = source
    if not isNearDepot(src) then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.job.name ~= Config.RequiredJob then return end

    -- Altijd willekeurige routes; seed RNG per start
    math.randomseed(os.time() + src)
    local route = makeRoute()
    PlayerJobs[src] = {
        active = true,
        route = route,
        idx = 1,
        done = false,
        carrying = false,
        remaining = #route,
        vehNetId = nil,
        delivered = 0,
        earned = 0
    }
    local male, female = getJobOutfit(xPlayer.job.name, xPlayer.job.grade)
    if (not male or male == '') and (not female or female == '') then
        print(('[deliveryjob] Geen outfit voor job=%s grade=%s in SQL job_grades'):format(xPlayer.job.name, tostring(xPlayer.job.grade)))
    end
    TriggerClientEvent('deliveryjob:dutyOutfit', src, male, female)
    TriggerClientEvent('deliveryjob:route', src, route)
end)

RegisterNetEvent('deliveryjob:setVeh', function(netId)
    local src = source
    local job = PlayerJobs[src]
    if not job or not job.active then return end
    job.vehNetId = netId
end)

RegisterNetEvent('deliveryjob:pickupBox', function(netId)
    local src = source
    local job = PlayerJobs[src]
    if not job or not job.active then return end
    if job.carrying or job.remaining <= 0 then return end
    -- CLient zorgt voor checks op nabijheid en voertuig
    job.carrying = true
    TriggerClientEvent('deliveryjob:boxOk', src)
end)

RegisterNetEvent('deliveryjob:delivered', function(idxClient)
    local src = source
    local job = PlayerJobs[src]
    if not job or not job.active then return end
    if idxClient ~= job.idx then return end
    if not job.carrying then return end

    local ped = GetPlayerPed(src)
    local p = GetEntityCoords(ped)
    local target = getPointPos(job.route[job.idx])
    if dist(p, target) > Config.DeliverRadius + 2.0 then return end

    -- Betalingsregeling: 400 per pakketje
    job.delivered = job.delivered + 1
    job.earned = job.earned + (Config.PayPerDrop or 400)

    job.carrying = false
    job.remaining = math.max(0, job.remaining - 1)
    job.idx = job.idx + 1
    if job.idx <= #job.route then
        TriggerClientEvent('deliveryjob:next', src, job.idx)
    else
        job.done = true
        TriggerClientEvent('deliveryjob:all_delivered', src)
    end
end)

RegisterNetEvent('deliveryjob:finish', function()
    local src = source
    local job = PlayerJobs[src]
    if not job or not job.active then return end
    if not isNearDepot(src) then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or xPlayer.job.name ~= Config.RequiredJob then return end
    -- uitbetaling als item en samenvatting
    local drops = job.delivered or 0
    local total = (job.earned or 0) + ((Config.FinishBonusPerDrop or 0) * drops)
    if total > 0 then
        local item = Config.PayItem or 'money'
        xPlayer.addInventoryItem(item, total)
    end
    TriggerClientEvent('deliveryjob:summary', src, drops, total)

    PlayerJobs[src] = nil
    TriggerClientEvent('deliveryjob:finished', src)
end)

RegisterNetEvent('deliveryjob:cancel', function()
    local src = source
    if PlayerJobs[src] then
        PlayerJobs[src] = nil
        TriggerClientEvent('deliveryjob:cancelled', src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    PlayerJobs[src] = nil
end)

-- eenmalige check bij resource start: outfits in SQL aanwezig?
AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        local jobName = Config.RequiredJob or 'deliverer'
        local has
        local q = 'SELECT COUNT(*) as cnt FROM job_grades WHERE job_name = ? AND ((skin_male IS NOT NULL AND skin_male <> "") OR (skin_female IS NOT NULL AND skin_female <> ""))'
        if MySQL and MySQL.single then
            local row = MySQL.single(q, {jobName})
            if row and row.cnt and row.cnt > 0 then has = true end
        else
            local ok, row = pcall(function() return exports.oxmysql:single(q, {jobName}) end)
            if ok and row and row.cnt and row.cnt > 0 then has = true end
        end
        if not has then
            print(('[deliveryjob] Geen job outfits gevonden in SQL voor job=%s (job_grades.skin_male/skin_female).'):format(jobName))
        end
    end)
end)
