local minimapEnabled = true

-- Função para ativar/desativar o minimap
local function ToggleMinimap(state)
    minimapEnabled = state
    DisplayRadar(state)
    
    if state then
        -- Substitui o minimap padrão pelo customizado
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.030, 0.111, 0.159)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
        
        -- Configurações adicionais para o minimap
        SetRadarBigmapEnabled(false, false)
        SetMinimapHideFow(true)
    end
end

-- Comando para alternar o minimap
RegisterCommand('togglemap', function()
    minimapEnabled = not minimapEnabled
    ToggleMinimap(minimapEnabled)
end, false)


RegisterNetEvent('ghost-hud:updateConfig', function(config)
    local shouldShow = config.hudEnabled and config.minimapEnabled
    ToggleMinimap(shouldShow)
end)