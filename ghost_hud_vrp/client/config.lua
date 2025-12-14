Config = {}

-- Configurações básicas
Config.UpdateInterval = 200 -- Intervalo de atualização em ms
Config.EnableMinimap = true -- Habilitar minimapa
Config.EnableStreetNames = true -- Habilitar nomes de rua
Config.EnableVehicleHud = true -- Habilitar HUD de veículo
Config.EnableWeaponHud = true -- Habilitar HUD de arma

-- Configurações de status (Fome/Sede/Stress)
Config.Status = {
    showHealth = true,
    showArmor = true,
    showHunger = true,
    showThirst = true,
    showStress = true,
    showStamina = true,
    showOxygen = true,

    hungerRate = 0.05, -- Taxa de diminuição de fome por minuto
    thirstRate = 0.08, -- Taxa de diminuição de sede por minuto
    stressRate = 0.03, -- Taxa de aumento de estresse por minuto (em situações de combate)
    stressReduction = 0.1 -- Taxa de redução de estresse por minuto (em situações calmas)
}

-- Configurações de voz (se usar mumble-voip/pma-voice)
Config.Voice = {
    enabled = true,
    levels = {
        whisper = 5.0,
        normal = 12.0,
        shout = 24.0
    }
}

-- Cores personalizadas (Referência para o JS)
Config.Colors = {
    health = { r = 255, g = 62, b = 62 },
    armor = { r = 62, g = 159, b = 255 },
    hunger = { r = 255, g = 170, b = 62 },
    thirst = { r = 62, g = 195, b = 255 },
    voice = { r = 76, g = 175, b = 80 },
    stamina = { r = 156, g = 39, b = 176 },
    stress = { r = 255, g = 152, b = 0 }
}