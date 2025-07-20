Config = {}

Config.Status = {
    showHealth = true,
    showArmor = true,
    showHunger = false,
    showThirst = false,
    showStress = true,
    showStamina = true,
    showOxygen = true,

    hungerRate = 0.05,
    thirstRate = 0.08,
    stressRate = 0.03,
    stressReduction = 0.1
}


-- Configurações básicas
Config.UpdateInterval = 200 -- Intervalo de atualização em ms
Config.EnableMinimap = true -- Habilitar minimapa
Config.EnableStreetNames = true -- Habilitar nomes de rua
Config.EnableVehicleHud = true -- Habilitar HUD de veículo
Config.EnableWeaponHud = true -- Habilitar HUD de arma

-- Configurações de voz (se usar mumble-voip)
Config.Voice = {
    enabled = true,
    levels = {
        whisper = 5.0,
        normal = 12.0,
        shout = 24.0
    }
}

-- Configurações de status
Config.Status = {
    hungerRate = 0.05, -- Taxa de diminuição de fome por minuto
    thirstRate = 0.08, -- Taxa de diminuição de sede por minuto
    stressRate = 0.03, -- Taxa de aumento de estresse por minuto (em situações de combate)
    stressReduction = 0.1 -- Taxa de redução de estresse por minuto (em situações calmas)
}

-- Posições padrão dos elementos
Config.Positions = {
    clock = { x = 160, y = 220 },
    status = { x = 0, y = 60 },
    vehicle = { x = 320, y = 34 },
    weapon = { x = 300, y = 220 }
}

-- Cores personalizadas
Config.Colors = {
    health = { r = 255, g = 62, b = 62 },
    armor = { r = 62, g = 159, b = 255 },
    hunger = { r = 255, g = 170, b = 62 },
    thirst = { r = 62, g = 195, b = 255 },
    voice = { r = 76, g = 175, b = 80 },
    stamina = { r = 156, g = 39, b = 176 },
    stress = { r = 255, g = 152, b = 0 }
}