-- Declaração de funções globais para evitar avisos de lint
local _PlayerId = PlayerId
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
local isPaused = false -- Pausa manual (comando toggle)
local isMenuOpen = false -- Pausa automática (ESC/Garagem)
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
    local proximity = _MumbleGetTalkerProximity and _MumbleGetTalkerProximity() or 2.0
    local previousLevel = currentVoiceLevel
    
    if proximity <= voiceLevels.whisper.distance then
        currentVoiceLevel = "whisper"
    elseif proximity <= voiceLevels.normal.distance then
        currentVoiceLevel = "normal"
    else
        currentVoiceLevel = "shout"
    end
    
    local talkingNow = _NetworkIsPlayerTalking(PlayerId())
    
    if previousLevel ~= currentVoiceLevel or isTalking ~= talkingNow then
        isTalking = talkingNow
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
local minimapEnabled = true
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
    
    local user_id = player_user_id or 0
    TriggerServerEvent('vrp_hud:updatePlayerData')

    -- Calcula a saúde (GTA V base health é 100, max é 200 geralmente)
    if rawHealth > 100 then
        healthPercent = math.min(100, ((rawHealth - 100) / 200) * 100)
    else
        healthPercent = 0
    end

    updateVoiceProximity()
    updateStreetName()

    SendNUIMessage({
        action = "updateStatus",
        health = healthPercent,
        armor = armor,
        hunger = GetResourceKvpInt("vRP:hunger") or 100, -- Ajuste conforme seu sistema de fome
        thirst = GetResourceKvpInt("vRP:thirst") or 100, -- Ajuste conforme seu sistema de sede
        stamina = stamina,
        stress = 0, -- Implementar lógica de stress se houver
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
        
        -- Garante que o minimapa apareça no carro (se habilitado)
        if not isPaused and not isMenuOpen and Config.EnableMinimap then
            DisplayRadar(true)
        end
    else
        SendNUIMessage({
            action = "vehicleHUD",
            show = false
        })
        -- Esconde minimapa a pé (opcional, estilo VRP padrão)
        -- DisplayRadar(false) 
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

-- =============================================
-- EXPORT PARA OUTROS SCRIPTS (GARAGEM, ETC)
-- =============================================
-- Use: exports['ghost_hud_vrp']:setHudVisible(false) quando abrir a garagem
exports('setHudVisible', function(visible)
    isMenuOpen = not visible
    SendNUIMessage({
        action = "toggleHUD",
        show = visible
    })
    if not visible then
        DisplayRadar(false)
    else
        DisplayRadar(Config.EnableMinimap)
    end
end)

-- =============================================
-- LOAD LAYOUT (CARREGAR POSIÇÕES SALVAS)
-- =============================================
function LoadUserLayout()
    local layoutString = GetResourceKvpString("ghost_hud_layout")
    if layoutString then
        local layout = json.decode(layoutString)
        SendNUIMessage({
            action = "loadLayout",
            layout = layout
        })
    end
end

-- =============================================
-- THREADS PRINCIPAIS
-- =============================================
Citizen.CreateThread(function()
    Wait(1000) -- Espera carregar NUI
    LoadUserLayout()
    
    while true do
        Citizen.Wait(200)
        
        -- Verifica Pause Menu (ESC)
        if IsPauseMenuActive() then
            if not isMenuOpen then
                isMenuOpen = true
                SendNUIMessage({ action = "toggleHUD", show = false })
                DisplayRadar(false)
            end
        else
            -- Se estava no menu e saiu (e não tem outro bloqueio externo)
            if isMenuOpen and not isPaused then 
                -- NOTA: Se você usou o export setHudVisible(false) externamente, 
                -- precisará chamar setHudVisible(true) lá também. 
                -- Esta verificação aqui é primariamente para o ESC.
                if not IsNuiFocused() then -- Só volta se não estiver em foco NUI
                    isMenuOpen = false
                    SendNUIMessage({ action = "toggleHUD", show = true })
                    DisplayRadar(Config.EnableMinimap)
                end
            end
        end

        if not isPaused and not isMenuOpen then
            updatePlayerStatus()
            updateVehicleHud()
            updateWeaponHud()
            SendNUIMessage({
                action = "getGameTime",
                hours = GetClockHours(),
                minutes = GetClockMinutes()
            })
        end
    end
end)

-- =============================================
-- EVENTOS E CALLBACKS
-- =============================================

RegisterNetEvent('vrp_hud:updateHUD')
AddEventHandler('vrp_hud:updateHUD', function(newConfig)
    minimapEnabled = newConfig.minimapEnabled
    ToggleMinimap(newConfig.hudEnabled and newConfig.minimapEnabled)
    SendNUIMessage({
        action = "updateHUD",
        config = newConfig
    })
end)

RegisterNetEvent('vrp_hud:openConfig')
AddEventHandler('vrp_hud:openConfig', function(configData)
    configOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openConfig",
        config = configData
    })
end)

-- Callback: Fecha configuração
RegisterNUICallback('closeConfig', function(data, cb)
    configOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

-- Callback: Salva configuração geral (toggles)
RegisterNUICallback('saveConfig', function(data, cb)
    TriggerServerEvent('vrp_hud:saveConfig', data.config)
    cb({})
end)

-- Callback: Salva posições (Drag & Drop)
RegisterNUICallback('saveLayout', function(data, cb)
    if data.layout then
        SetResourceKvp("ghost_hud_layout", json.encode(data.layout))
    end
    cb({})
end)

-- Callback: Resetar layout
RegisterNUICallback('resetLayout', function(data, cb)
    DeleteResourceKvp("ghost_hud_layout")
    cb({})
end)

-- Callback: Modo de edição (foco)
RegisterNUICallback('setEditMode', function(data, cb)
    SetNuiFocus(data.enabled, data.enabled)
    cb({})
end)

RegisterNUICallback('updateMinimap', function(data, cb)
    if data.show ~= nil then
        ToggleMinimap(data.show)
    end
    cb({})
end)

-- =============================================
-- CINTO DE SEGURANÇA
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
                DisableControlAction(0, 75, true) -- Desativa sair do veículo
            end
            
            if IsControlJustReleased(0, 47) then -- Tecla G
                cintoSeguranca = not cintoSeguranca
                -- Se tiver som, descomente: TriggerEvent("vrp_sound:source", cintoSeguranca and "belt" or "unbelt", 0.1)
                
                -- Flag 32: PED_FLAG_CAN_FLY_THRU_WINDSCREEN (true = não voa, false = voa)
                -- Se cinto estiver ON, NÃO voa (false no SetPedConfigFlag)
                SetPedConfigFlag(ped, 32, not cintoSeguranca) 
                
                if cintoSeguranca then
                    SendNotification("CINTO", "Cinto colocado", "sucesso", 2000)
                else
                    SendNotification("CINTO", "Cinto retirado", "aviso", 2000)
                end
            end
        elseif exNoCarro then
            exNoCarro = false
            cintoSeguranca = false
            SetPedConfigFlag(ped, 32, true) -- Reseta flag ao sair
        end
        Wait(espera)
    end
end)

-- Inicialização
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('vrp_hud:updatePlayerData')
    ToggleMinimap(Config.EnableMinimap)
    LoadUserLayout()
end)

RegisterNetEvent("Notify")
AddEventHandler("Notify", function(type, message, time)
    local typeMap = {
        ["negado"] = "error",
        ["aviso"] = "warning",
        ["sucesso"] = "success",
        ["policia"] = "policia",
        ["hospital"] = "hospital",
        ["mecanica"] = "mecanica"
    }
    local notifyType = typeMap[type] or "info"
    SendNotification(type:upper(), message, notifyType, time)
end)