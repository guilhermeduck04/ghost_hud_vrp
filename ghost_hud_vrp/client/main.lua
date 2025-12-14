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
local isPaused = false 
local isMenuOpen = false 
local streetName = ""
local configOpen = false
local cintoSeguranca = false
local minimapEnabled = true 
local CurrentConfig = {} 

Config = Config or {}

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

RegisterNetEvent('pma-voice:setTalkingMode')
AddEventHandler('pma-voice:setTalkingMode', function(mode)
    local modes = { [1] = "whisper", [2] = "normal", [3] = "shout" }
    currentVoiceLevel = modes[mode] or "normal"
    SendNUIMessage({
        action = "updateStatus",
        voiceLevel = currentVoiceLevel,
        isTalking = NetworkIsPlayerTalking(PlayerId())
    })
end)

function updateVoiceLogic()
    local talkingNow = NetworkIsPlayerTalking(PlayerId())
    if isTalking ~= talkingNow then
        isTalking = talkingNow
        SendNUIMessage({
            action = "updateStatus",
            voiceLevel = currentVoiceLevel,
            isTalking = isTalking
        })
    end
end

-- =============================================
-- RÁDIO
-- =============================================
local lastRadioFreq = 0
function updateRadioLogic()
    local currentFreq = LocalPlayer.state.radioChannel
    if not currentFreq then currentFreq = 0 end

    if currentFreq ~= lastRadioFreq then
        lastRadioFreq = currentFreq
        SendNUIMessage({
            action = "updateRadio",
            freq = currentFreq
        })
    end
end

-- =============================================
-- MINIMAP
-- =============================================
local function ToggleMinimap(state)
    if state then
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.030, 0.111, 0.159)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
        SetRadarBigmapEnabled(false, false)
        SetMinimapHideFow(true)
        SetRadarZoom(1100)
    end
    DisplayRadar(state)
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
    if data.emprego then emprego = data.emprego end
    if data.user_id then player_user_id = data.user_id end
end)

function updatePlayerStatus()
    local playerPed = PlayerPedId()
    local rawHealth = GetEntityHealth(playerPed)
    local healthPercent = 0
    local armor = GetPedArmour(playerPed)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    
    TriggerServerEvent('vrp_hud:updatePlayerData')

    if rawHealth > 100 then
        healthPercent = math.min(100, ((rawHealth - 100) / 200) * 100)
    else
        healthPercent = 0
    end

    updateVoiceLogic()
    updateRadioLogic()
    updateStreetName()

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
        user_id = player_user_id or 0,
        streetName = streetName or ""
    })
end

-- =============================================
-- NOTIFICAÇÕES (CORREÇÃO DE TEMPO)
-- =============================================
function SendNotification(title, message, type, duration)
    local jsType = "info"
    if type == "sucesso" then jsType = "success"
    elseif type == "negado" or type == "erro" then jsType = "error"
    elseif type == "aviso" then jsType = "warning"
    elseif type == "policia" or type == "hospital" or type == "mecanica" then jsType = type 
    end

    -- CORREÇÃO CRÍTICA: Detecta se é ms ou segundos
    local dur = 3000
    if duration then
        local t = tonumber(duration)
        if t then
            if t > 100 then dur = t else dur = t * 1000 end
        end
    end

    SendNUIMessage({
        action = "showNotification",
        title = title,
        message = message,
        type = jsType,
        duration = dur
    })
end
exports('SendNotification', SendNotification)

exports('setHudVisible', function(visible)
    isMenuOpen = not visible
    SendNUIMessage({ action = "toggleHUD", show = visible })
    if not visible then
        DisplayRadar(false)
    else
        if minimapEnabled then DisplayRadar(true) end
    end
end)

function updateVehicleHud()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local speed = GetEntitySpeed(vehicle) * 3.6
        local fuel = GetVehicleFuelLevel(vehicle)
        local rpm = GetVehicleCurrentRpm(vehicle)
        local engineOn = GetIsVehicleEngineRunning(vehicle)
        local locked = GetVehicleDoorLockStatus(vehicle) == 2
        
        local engineHealth = (GetVehicleEngineHealth(vehicle) / 1000.0) * 100
        local bodyHealth = (GetVehicleBodyHealth(vehicle) / 1000.0) * 100
        
        local gear = GetVehicleCurrentGear(vehicle)
        if gear == 0 then gear = "R" elseif gear == 1 then gear = "1" end
        
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
        SendNUIMessage({ action = "hideWeapon" })
    end
end

function getGameTime()
    return { hours = GetClockHours(), minutes = GetClockMinutes() }
end

function LoadUserLayout()
    local layout = GetResourceKvpString("ghost_hud_layout")
    if layout and layout ~= "" then
        SendNUIMessage({
            action = "loadLayout",
            layout = json.decode(layout)
        })
    end
end

-- =============================================
-- THREAD PRINCIPAL
-- =============================================
Citizen.CreateThread(function()
    Wait(1000)
    LoadUserLayout()

    while true do
        Citizen.Wait(200)
        
        if IsPauseMenuActive() then
            if not isMenuOpen then
                isMenuOpen = true
                SendNUIMessage({ action = "toggleHUD", show = false })
                DisplayRadar(false)
            end
        else
            if isMenuOpen and not isPaused then 
                if not IsNuiFocused() then
                    isMenuOpen = false
                    SendNUIMessage({ action = "toggleHUD", show = true })
                    if minimapEnabled then DisplayRadar(true) end
                end
            end
        end

        if not isPaused and not isMenuOpen then
            updatePlayerStatus()
            updateVehicleHud()
            updateWeaponHud()
            
            if minimapEnabled then
                DisplayRadar(true)
            end

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

RegisterNetEvent('vrp_hud:updateHUD')
AddEventHandler('vrp_hud:updateHUD', function(newConfig)
    CurrentConfig = newConfig 
    minimapEnabled = newConfig.minimapEnabled
    if not isMenuOpen and not isPaused then
        DisplayRadar(newConfig.hudEnabled and newConfig.minimapEnabled)
    end
    SendNUIMessage({
        action = "updateHUD",
        config = newConfig
    })
end)

RegisterNetEvent('vrp_hud:openConfig')
AddEventHandler('vrp_hud:openConfig', function(configData)
    configOpen = true
    local configToSend = (next(CurrentConfig) ~= nil) and CurrentConfig or configData
    SendNUIMessage({ action = "openConfig", config = configToSend })
    SetNuiFocus(true, true)
end)

RegisterNetEvent("Notify")
AddEventHandler("Notify", function(type, message, time)
    local title = "INFORMAÇÃO"
    if type == "negado" then title = "NEGADO"
    elseif type == "aviso" then title = "AVISO"
    elseif type == "sucesso" then title = "SUCESSO"
    elseif type == "policia" then title = "POLÍCIA"
    end
    
    SendNotification(title, message, type, time)
end)

-- Eventos de Progresso (Tratados)
local function handleProgress(time, text)
    local dur = 3000
    if time then
        local t = tonumber(time)
        if t > 100 then dur = t else dur = t * 1000 end
    end
    SendNUIMessage({ action = "progress", duration = dur })
end

RegisterNetEvent("progress")
AddEventHandler("progress", handleProgress)

RegisterNetEvent("Progress")
AddEventHandler("Progress", handleProgress)

RegisterNetEvent('vrp_hud:startProgress')
AddEventHandler('vrp_hud:startProgress', function(duration)
    handleProgress(duration, "")
end)

exports('startProgress', function(duration)
    TriggerEvent('vrp_hud:startProgress', duration)
end)

RegisterNUICallback('closeConfig', function(data, cb)
    configOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('saveConfig', function(data, cb)
    if data.config then
        if data.config.minimapEnabled ~= nil then
            minimapEnabled = data.config.minimapEnabled
        end
        CurrentConfig = data.config
    end
    TriggerServerEvent('vrp_hud:saveConfig', data.config)
    cb('ok')
end)

RegisterNUICallback('nuiReady', function(data, cb)
    Wait(500)
    LoadUserLayout()
    TriggerServerEvent('vrp_hud:updatePlayerData')
    if minimapEnabled then ToggleMinimap(true) end
    cb('ok')
end)

RegisterNUICallback('saveLayout', function(data, cb)
    if data.layout then SetResourceKvp("ghost_hud_layout", json.encode(data.layout)) end
    cb('ok')
end)

RegisterNUICallback('resetLayout', function(data, cb)
    DeleteResourceKvp("ghost_hud_layout")
    cb('ok')
end)

RegisterNUICallback('setEditMode', function(data, cb)
    SetNuiFocus(data.enabled, data.enabled)
    cb('ok')
end)

RegisterNUICallback('updateMinimap', function(data, cb)
    if data.show ~= nil then
        minimapEnabled = data.show
        DisplayRadar(data.show)
    end
    cb('ok')
end)

RegisterNUICallback('getGameTime', function(_, cb)
    cb({ hours = GetClockHours(), minutes = GetClockMinutes() })
end)

-- Cinto
local exNoCarro = false
Citizen.CreateThread(function()
    while true do
        local espera = 1000
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped)
        
        if veh ~= 0 and (exNoCarro or GetVehicleClass(veh) ~= 8) then
            espera = 5
            exNoCarro = true
            if cintoSeguranca then DisableControlAction(0, 75) end
            if IsControlJustReleased(0, 47) then 
                cintoSeguranca = not cintoSeguranca
                TriggerEvent("vrp_sound:source", cintoSeguranca and "belt" or "unbelt", 0.1)
                SetPedConfigFlag(ped, 32, not cintoSeguranca)
                
                if cintoSeguranca then
                    SendNotification("CINTO", "Cinto Colocado", "sucesso", 2000)
                else
                    SendNotification("CINTO", "Cinto Retirado", "aviso", 2000)
                end
            end
        elseif exNoCarro then
            exNoCarro = false
            cintoSeguranca = false
            SetPedConfigFlag(ped, 32, true)
        end
        Wait(espera)
    end
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('vrp_hud:updatePlayerData')
    ToggleMinimap(minimapEnabled)
    LoadUserLayout()
end)

RegisterCommand('togglemap', function()
    minimapEnabled = not minimapEnabled
    ToggleMinimap(minimapEnabled)
    if CurrentConfig then CurrentConfig.minimapEnabled = minimapEnabled end
    SendNUIMessage({ action = "updateHUD", config = CurrentConfig })
end, false)

RegisterCommand("hudconfig", function()
    TriggerEvent("vrp_hud:openConfig", CurrentConfig)
end)

RegisterCommand('testenotify', function()
    TriggerEvent("Notify", "sucesso", "Teste OK!", 5)
end, false)