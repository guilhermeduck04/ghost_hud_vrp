local isPaused = false
local playerData = {}
local streetName = ""

-- Função para atualizar o nome da rua
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

function getVoiceLevel()
    local voiceDistance = MumbleGetTalkerProximity()

    if voiceDistance <= Config.Voice.levels.whisper then
        return "whisper"
    elseif voiceDistance <= Config.Voice.levels.normal then
        return "normal"
    else
        return "shout"
    end
end


-- Atualizar status do jogador
function updatePlayerStatus()
    local playerPed = PlayerPedId()
    
    local rawHealth = GetEntityHealth(playerPed)
    local health = math.min(rawHealth, 200) / 2
    local armor = GetPedArmour(playerPed)
    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

    local job = "Desempregado" -- você pode trocar por export real do seu sistema de emprego
    local user_id = GetPlayerServerId(PlayerId())

    voiceLevel = getVoiceLevel()

    SendNUIMessage({
        action = "updateStatus",
        health = health > 0 and health or 0,
        armor = armor,
        hunger = GetResourceKvpInt("vRP:hunger") or 100,
        thirst = GetResourceKvpInt("vRP:thirst") or 100,
        stamina = stamina,
        stress = 0,
        voicePercent = 50,
        isTalking = NetworkIsPlayerTalking(PlayerId()),
        voiceLevel = getVoiceLevel(),
        job = job,
        user_id = user_id
    })

end

-- Atualizar HUD do veículo
function updateVehicleHud()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local speed = GetEntitySpeed(vehicle) * 3.6
        local fuel = GetVehicleFuelLevel(vehicle)
        local rpm = GetVehicleCurrentRpm(vehicle)
        local gear = GetVehicleCurrentGear(vehicle)
        local engineOn = GetIsVehicleEngineRunning(vehicle)
        local seatbeltOn = false -- Implementar sistema de cinto
        local locked = GetVehicleDoorLockStatus(vehicle) == 2
        
        SendNUIMessage({
            action = "vehicleHUD",
            show = true,
            speed = math.floor(speed),
            fuel = fuel,
            rpm = rpm,
            gear = gear,
            engine = engineOn,
            seatbelt = seatbeltOn,
            locked = locked
        })
    else
        SendNUIMessage({
            action = "vehicleHUD",
            show = false
        })
    end
end

-- Atualizar HUD de arma
function updateWeaponHud()
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)

    if weapon and weapon ~= `WEAPON_UNARMED` then
        local ammoTotal = GetAmmoInPedWeapon(playerPed, weapon)
        local _, ammoInClip = GetAmmoInClip(playerPed, weapon)

        SendNUIMessage({
            action = "weaponHUD",
            show = true,
            ammo = ammoInClip,
            totalAmmo = ammoTotal
        })
    else
        SendNUIMessage({
            action = "weaponHUD",
            show = false
        })
    end
end


-- Obter hora do jogo
function getGameTime()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    
    return {
        hours = hours,
        minutes = minutes
    }
end

-- Thread principal
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

Citizen.CreateThread(function()
    while true do
        Wait(0)
        HideHudComponentThisFrame(1)  -- HUD (Retângulo superior direito)
        HideHudComponentThisFrame(2)  -- HUD do radar
        HideHudComponentThisFrame(3)  -- Nome do veículo
        HideHudComponentThisFrame(4)  -- Armas
        HideHudComponentThisFrame(6)  -- Vida e colete
        HideHudComponentThisFrame(7)  -- Área de jogo
        HideHudComponentThisFrame(8)  -- Armas e munição
        HideHudComponentThisFrame(9)  -- Dinheiro
        HideHudComponentThisFrame(13) -- Cash
        HideHudComponentThisFrame(14) -- Área de missão
        HideHudComponentThisFrame(17) -- Save game
        HideHudComponentThisFrame(20) -- Armas
    end
end)

-- Evento para abrir configuração
RegisterNetEvent('vrp_hud:openConfig')
AddEventHandler('vrp_hud:openConfig', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "forceShowConfig"
    })
end)

-- Evento para definir configuração
RegisterNetEvent('vrp_hud:setConfig')
AddEventHandler('vrp_hud:setConfig', function(newConfig)
    SendNUIMessage({
        action = "updateHUD",
        config = newConfig
    })
end)

-- Evento para atualizar dados do jogador
RegisterNetEvent('vrp_hud:updatePlayerData')
AddEventHandler('vrp_hud:updatePlayerData', function(data)
    playerData = data
    SendNUIMessage({
        action = "updatePlayerData",
        user_id = data.user_id,
        job = data.job
    })
end)

RegisterNUICallback("getGameTime", function(_, cb)
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    cb({ hours = hour, minutes = minute })
end)

-- NUI Callbacks
RegisterNUICallback('closeConfig', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('saveConfig', function(data, cb)
    TriggerServerEvent('vrp_hud:saveConfig', data.config)
    cb({})
end)

-- Pausar HUD quando o jogo estiver pausado
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        isPaused = IsPauseMenuActive()
    end
end)

-- Inicialização
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('vrp_hud:updatePlayerData')
end)

-- Comando para abrir configuração
RegisterCommand("hudconfig", function()
    TriggerEvent('vrp_hud:openConfig')
end, false)