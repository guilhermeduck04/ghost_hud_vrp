local Proxy = module("vrp", "lib/Proxy")
local Tunnel = module("vrp", "lib/Tunnel")
vRP = Proxy.getInterface("vRP")

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
        voice = { 
            enabled = true,
            levels = {
                whisper = 3.0,
                normal = 8.0,
                shout = 15.0
            }
        },
        vehicle = { enabled = true },
        weapon = { enabled = true },
        org = { enabled = true },
        id = { enabled = true },
        clock = { enabled = true }
    }
}

-- =============================================
-- FUNÇÕES ORIGINAIS
-- =============================================
function getDefaultConfig()
    return json.decode(json.encode(config))
end

RegisterNetEvent('vrp_hud:nuiReady')
AddEventHandler('vrp_hud:nuiReady', function()
    local src = source
    TriggerClientEvent('vrp_hud:setConfig', src, config)
end)

RegisterNetEvent('vrp_hud:saveConfig')
AddEventHandler('vrp_hud:saveConfig', function(newConfig)
    local src = source
    config = newConfig
    TriggerClientEvent('vrp_hud:setConfig', -1, config)
end)

RegisterNetEvent('vrp_hud:updatePlayerData')
AddEventHandler('vrp_hud:updatePlayerData', function()
    local src = source
    local user_id = vRP.getUserId(src)
    if user_id then
        local groupv = vRP.getUserGroupByType(user_id, "org") or "Desempregado"
        TriggerClientEvent('vrp_hud:updatePlayerData', src, {
            user_id = user_id,
            emprego = groupv
        })
    end
end)

RegisterServerEvent('vrp:getUserGroup')
AddEventHandler('vrp:getUserGroup', function(cb)
    local user_id = vRP.getUserId(source)
    if user_id then
        cb(vRP.getUserGroupByType(user_id, "permissao") or "user")
    else
        cb("user")
    end
end)

local function SendNotify(source, type, message, time)
    TriggerClientEvent("vrp_hud:SendNotification", source, {
        type = type,
        title = type:upper(),
        message = message,
        time = time or 5
    })
end


TriggerClientEvent("vrp_hud:SendNotification", -1, {type = "staff", title = "TESTE", message = "Mensagem de teste", time = 10})

-- =============================================
-- COMANDOS ORIGINAIS
-- =============================================
RegisterCommand("hudconfig", function(source, args, rawCommand)
    TriggerClientEvent('vrp_hud:openConfig', source, config)
end, false)

-- Comando para enviar notificações personalizadas usando vRP
RegisterCommand("notify", function(source, args)
    if source == 0 then -- Console
        SendNotify(-1, "staff", table.concat(args, " "), 10)
    else
        TriggerClientEvent("vrp:getUserGroup", source, function(perm)
            if perm == "admin.permissao" then
                SendNotify(-1, "staff", table.concat(args, " "), 10)
            else
                SendNotify(source, "negado", "Você não tem permissão", 5)
            end
        end)
    end
end, true)

-- Comando para notificação de polícia
RegisterCommand("policenotify", function(source, args)
    if source == 0 then -- Console
        SendNotify(-1, "policia", table.concat(args, " "), 10)
    else
        TriggerClientEvent("vrp:getUserGroup", source, function(perm)
            if perm == "policia.permissao" then
                SendNotify(-1, "policia", table.concat(args, " "), 10)
            else
                SendNotify(source, "negado", "Você não tem permissão", 5)
            end
        end)
    end
end, true)

-- Comando para notificação de hospital
RegisterCommand("medicnotify", function(source, args)
    if source == 0 then -- Console
        SendNotify(-1, "hospital", table.concat(args, " "), 10)
    else
        TriggerClientEvent("vrp:getUserGroup", source, function(perm)
            if perm == "paramedico.permissao" then
                SendNotify(-1, "hospital", table.concat(args, " "), 10)
            else
                SendNotify(source, "negado", "Você não tem permissão", 5)
            end
        end)
    end
end, true)

-- Comando para notificação de mecânica
RegisterCommand("mecnotify", function(source, args)
    if source == 0 then -- Console
        SendNotify(-1, "mecanica", table.concat(args, " "), 10)
    else
        TriggerClientEvent("vrp:getUserGroup", source, function(perm)
            if perm == "mecanico.permissao" then
                SendNotify(-1, "mecanica", table.concat(args, " "), 10)
            else
                SendNotify(source, "negado", "Você não tem permissão", 5)
            end
        end)
    end
end, true)
