-- Declaração de funções globais para evitar avisos de lint
local _PlayerId = PlayerId
local _GetPlayerServerId = GetPlayerServerId
local _NetworkIsPlayerTalking = NetworkIsPlayerTalking
local _MumbleGetTalkerProximity = MumbleGetTalkerProximity

local vRP
Citizen.CreateThread(function()
    while vRP == nil do
        TriggerEvent('vRP:getInterface', function(obj)
            vRP = obj
        end)
        Citizen.Wait(1000)
    end
end)
local emprego = "Desempregado"
local player_user_id = 0

-- Funções seguras
local function SafePlayerId()
    return _PlayerId and _PlayerId() or 0
end

local function SafeGetPlayerServerId()
    return _GetPlayerServerId and _GetPlayerServerId(PlayerId()) or 0
end

local function SafeNetworkIsPlayerTalking()
    return _NetworkIsPlayerTalking and _NetworkIsPlayerTalking(PlayerId()) or false
end

local function SafeMumbleGetTalkerProximity()
    return _MumbleGetTalkerProximity and _MumbleGetTalkerProximity() or 1.0
end


-- Variáveis locais
local isPaused = false
local playerData = {}
local streetName = ""
local configOpen = false
Config = Config or {}
local cintoSeguranca = false

-- =============================================
-- SISTEMA DE VOZ
-- =============================================
local voiceLevels = {
    whisper = { distance = 3.0, label = "Sussurro" },
    normal = { distance = 8.0, label = "Normal" },
    shout = { distance = 15.0, label = "Gritar" }
}
local currentVoiceLevel = "normal"
local isTalking = false

function updateVoiceProximity()
    local proximity = MumbleGetTalkerProximity()
    local previousLevel = currentVoiceLevel -- Guarda o nível anterior
    
    if proximity <= voiceLevels.whisper.distance then
        currentVoiceLevel = "whisper"
    elseif proximity <= voiceLevels.normal.distance then
        currentVoiceLevel = "normal"
    else
        currentVoiceLevel = "shout"
    end
    
    -- Só atualiza se realmente mudou ou se é a primeira vez
    if previousLevel ~= currentVoiceLevel or isTalking ~= NetworkIsPlayerTalking(PlayerId()) then
        isTalking = NetworkIsPlayerTalking(PlayerId())
        SendNUIMessage({
            action = "updateStatus",
            voiceLevel = currentVoiceLevel,
            isTalking = isTalking
        })
    end
end

-- =============================================
-- MINIMAP
-- =============================================
local function ToggleMinimap(state)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.030, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
    SetRadarBigmapEnabled(false, false)
    SetMinimapHideFow(true)

    DisplayRadar(state)
    
    SetRadarZoom(1100)
end

-- =============================================
-- FUNÇÕES HUD
-- =============================================
function updateStreetName()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    streetName = GetStreetNameFromHashKey(streetHash)
    
    SendNUIMessage({
        action = "updateStreet",
        streetName = streetName
    })
end

RegisterNetEvent('vrp_hud:updatePlayerData')
AddEventHandler('vrp_hud:updatePlayerData', function(data)
    if data.emprego then
        emprego = data.emprego
    end
    if data.user_id then
        player_user_id = data.user_id
    end
end)

function updatePlayerStatus()
    local playerPed = PlayerPedId()
    local rawHealth = GetEntityHealth(playerPed)
    local healthPercent = 0
    local armor = GetPedArmour(playerPed)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    
    -- Usa o user_id enviado pelo servidor (sincronizado)
    local user_id = player_user_id or 0

    -- Solicita atualização do servidor (não depende do retorno imediato)
    TriggerServerEvent('vrp_hud:updatePlayerData')

    local job = "Desempregado"
    if vRP and vRP.getUserGroupByType and user_id and user_id ~= 0 then
        job = vRP.getUserGroupByType(user_id, "job") or "Desempregado"
        local org = vRP.getUserGroupByType(user_id, "org") or ""
        if job == "Desempregado" and org ~= "" then
            job = org
        end
    end

    
    -- Calcula a saúde
    if rawHealth > 100 then
        healthPercent = math.min(100, ((rawHealth - 100) / 200) * 100)
    end

    -- Atualiza o status da voz
    updateVoiceProximity()
    
    -- Atualiza o nome da rua
    updateStreetName()

    -- Envia os dados para a NUI
    SendNUIMessage({
        action = "updateStatus",
        health = healthPercent,
        armor = armor,
        hunger = GetResourceKvpInt("vRP:hunger") or 100,
        thirst = GetResourceKvpInt("vRP:thirst") or 100,
        stamina = stamina,
        stress = 0,
        isTalking = isTalking,
        voiceLevel = currentVoiceLevel,
        job = emprego,
        user_id = user_id or 0,
        streetName = streetName or ""
    })
end

function SendNotification(title, message, type, duration)
    local payload = {
        action = "showNotification",
        title = title,
        message = message,
        type = type
    }
    if duration ~= nil then payload.duration = duration end
    SendNUIMessage(payload)
end

exports('SendNotification', SendNotification)



function updateVehicleHud()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local speed = GetEntitySpeed(vehicle) * 3.6
        local fuel = GetVehicleFuelLevel(vehicle)
        local rpm = GetVehicleCurrentRpm(vehicle)
        local engineOn = GetIsVehicleEngineRunning(vehicle)
        local locked = GetVehicleDoorLockStatus(vehicle) == 2
        
        -- Estado do veículo (0-100%)
        local engineHealth = (GetVehicleEngineHealth(vehicle) / 1000.0) * 100
        local bodyHealth = (GetVehicleBodyHealth(vehicle) / 1000.0) * 100
        
        -- Marcha atual
        local gear = GetVehicleCurrentGear(vehicle)
        if gear == 0 then
            gear = "R" -- Ré
        elseif gear == 1 then
            gear = "1" -- Neutro
        end
        
        SendNUIMessage({
            action = "vehicleHUD",
            show = true,
            speed = math.floor(speed),
            fuel = fuel,
            rpm = rpm,
            engine = engineOn,
            cinto = cintoSeguranca,
            locked = locked,
            engineHealth = engineHealth > 0 and engineHealth or 0,
            bodyHealth = bodyHealth > 0 and bodyHealth or 0,
            gear = tostring(gear)
        })
    else
        SendNUIMessage({
            action = "vehicleHUD",
            show = false
        })
    end
end

function updateWeaponHud()
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)

    if weapon and weapon ~= `WEAPON_UNARMED` then
        local ammoTotal = GetAmmoInPedWeapon(playerPed, weapon)
        local _, ammoInClip = GetAmmoInClip(playerPed, weapon)

        SendNUIMessage({
            action = "updateWeapon",
            show = true,
            ammoClip = ammoInClip,
            ammoInventory = ammoTotal
        })
    else
        SendNUIMessage({
            action = "hideWeapon"
        })
    end
end

function getGameTime()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    
    return {
        hours = hours,
        minutes = minutes
    }
end

-- =============================================
-- THREADS
-- =============================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        
        if not isPaused then
            updatePlayerStatus()
            updateStreetName()
            updateVehicleHud()
            updateWeaponHud()
            SendNUIMessage({
                action = "getGameTime",
                hours = getGameTime().hours,
                minutes = getGameTime().minutes
            })
        end
    end
end)


-- =============================================
-- EVENTOS
-- =============================================


-- Recebe a configuração atualizada do servidor
RegisterNetEvent('vrp_hud:updateHUD')
AddEventHandler('vrp_hud:updateHUD', function(newConfig)
    minimapEnabled = newConfig.minimapEnabled
    DisplayRadar(newConfig.hudEnabled and newConfig.minimapEnabled)
    SendNUIMessage({
        action = "updateHUD",
        config = newConfig
    })
end)

RegisterNetEvent('vrp_hud:openConfig')
AddEventHandler('vrp_hud:openConfig', function(configData)
    configOpen = true
    SendNUIMessage({
        action = "openConfig",
        config = configData
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent("vrp_hud:SendNotification")
AddEventHandler("vrp_hud:SendNotification", function(data)
    local payload = {
        action = "showNotification",
        title = data.title,
        message = data.message,
        type = data.type
    }
    if data.time ~= nil then
        local t = tonumber(data.time)
        if t then
            if t >= 1000 then
                payload.duration = t
            else
                payload.duration = t * 1000
            end
        end
    end
    SendNUIMessage(payload)
end)

-- Callback para fechar o painel
RegisterNUICallback('closeConfig', function(data, cb)
    configOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

-- Callback para salvar a configuração
RegisterNUICallback('saveConfig', function(data, cb)
    TriggerServerEvent('vrp_hud:saveConfig', data.config)
    cb({})
end)

-- Callback para o JS atualizar o minimapa
RegisterNUICallback('updateMinimap', function(data, cb)
    if data.show ~= nil then
        DisplayRadar(data.show)
    end
    cb({})
end)

-- Callback para o JS pegar a hora do jogo
RegisterNUICallback('getGameTime', function(_, cb)
    cb({ hours = GetClockHours(), minutes = GetClockMinutes() })
end)

-- =============================================
-- SISTEMA DE CINTO
-- =============================================
local exNoCarro = false

Citizen.CreateThread(function()
    while true do
        local espera = 1000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped)
        
        if veh ~= 0 and (exNoCarro or GetVehicleClass(veh) ~= 8) then
            espera = 5
            exNoCarro = true
            
            if cintoSeguranca then
                DisableControlAction(0, 75)
            end
            
            if IsControlJustReleased(0, 47) then -- Tecla G
                cintoSeguranca = not cintoSeguranca -- Remove o 'local' daqui
                TriggerEvent("vrp_sound:source", cintoSeguranca and "belt" or "unbelt", 0.1)
                SetPedConfigFlag(ped, 32, not cintoSeguranca)
                print("[DEBUG] Cinto alterado para:", cintoSeguranca) -- Debug adicional
            end
        elseif exNoCarro then
            exNoCarro = false
            cintoSeguranca = false -- Remove o 'local' daqui
            SetPedConfigFlag(ped, 32, true)
        end
        
        Wait(espera)
    end
end)
-- =============================================
-- INICIALIZAÇÃO
-- =============================================
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('vrp_hud:updatePlayerData')
    -- On spawn, ensure minimap state is correctly applied
    if Config.minimapEnabled ~= nil then
        ToggleMinimap(Config.minimapEnabled)
    else
        -- Fallback to default if Config.minimapEnabled is not set yet
        ToggleMinimap(true) 
    end
end)

-- Initialize minimap state on resource start
Citizen.CreateThread(function()
    -- Wait for config to be loaded from server.lua
    while Config.hudEnabled == nil do
        Citizen.Wait(100)
    end
    ToggleMinimap(Config.minimapEnabled)
end)

-- Comando para debug (opcional)
RegisterCommand('togglemap', function()
    minimapEnabled = not minimapEnabled
    ToggleMinimap(minimapEnabled)
    -- Also update the NUI config to reflect the change
    Config.minimapEnabled = minimapEnabled
    SendNUIMessage({
        action = "updateHUD",
        config = Config
    })
end, false)

    
RegisterNetEvent("Notify")
AddEventHandler("Notify", function(type, message, time)
    local title = ""
    local notifyType = type
    
    -- Mapeamento dos títulos
    if type == "negado" then
        title = "NEGADO"
    elseif type == "aviso" then
        title = "AVISO"
    elseif type == "sucesso" then
        title = "SUCESSO"
    elseif type == "policia" then
        title = "POLÍCIA"
    elseif type == "hospital" then
        title = "HOSPITAL"
    elseif type == "mecanica" then
        title = "MECÂNICA"
    else
        title = "INFORMAÇÃO"
        notifyType = "info"
    end
    
    local payload = {
        action = "Notify",
        type = notifyType,
        title = title,
        message = message
    }
    if time ~= nil then payload.time = time end
    SendNUIMessage(payload)
end)


-- Comando simplificado para teste
RegisterCommand('testenotify', function()
    TriggerEvent("Notify", "negado", "Teste de notificação negado", 5)
    Wait(2000)
    TriggerEvent("Notify", "aviso", "Teste de notificação aviso", 5)
    Wait(2000)
    TriggerEvent("Notify", "sucesso", "Teste de notificação sucesso", 5)
    Wait(2000)
    TriggerEvent("Notify", "info", "Teste de notificação info", 5)
end, false)