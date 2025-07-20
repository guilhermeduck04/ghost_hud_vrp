local config = {
    hudEnabled = true,
    minimapEnabled = true,
    showValues = true,
    elements = {
        health = { enabled = true },
        armor = { enabled = true },
        hunger = { enabled = true },
        thirst = { enabled = true },
        stamina = { enabled = true },
        stress = { enabled = true },
        voice = { enabled = true },
        vehicle = { enabled = true },
        weapon = { enabled = true },
        coupon = { enabled = true },
        job = { enabled = true },
        id = { enabled = true },
        clock = { enabled = true }
    }
}

-- Função para obter a configuração padrão
function getDefaultConfig()
    return json.decode(json.encode(config))
end

-- Evento para quando o NUI estiver pronto
RegisterNetEvent('vrp_hud:nuiReady')
AddEventHandler('vrp_hud:nuiReady', function()
    local src = source
    TriggerClientEvent('vrp_hud:setConfig', src, config)
end)

-- Evento para salvar configuração
RegisterNetEvent('vrp_hud:saveConfig')
AddEventHandler('vrp_hud:saveConfig', function(newConfig)
    local src = source
    config = newConfig
    TriggerClientEvent('vrp_hud:setConfig', src, config)
end)

-- Atualizar dados do jogador
RegisterNetEvent('vrp_hud:updatePlayerData')
AddEventHandler('vrp_hud:updatePlayerData', function()
    local src = source
    local user_id = vRP.getUserId(src)
    if user_id then
        local job = vRP.getUserGroupByType(user_id, "job") or "Desempregado"
        TriggerClientEvent('vrp_hud:updatePlayerData', src, {
            user_id = user_id,
            job = job
        })
    end
end)

-- Comando para abrir configuração
RegisterCommand("hudconfig", function(source, args, rawCommand)
    TriggerClientEvent('vrp_hud:openConfig', source)
end, false)