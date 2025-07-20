CreateThread(function()
    local lastTalkingState = false
    local lastVoiceMode = nil
    
    while true do
        Wait(100) -- Atualiza a cada 100ms
        local voiceLevel = LocalPlayer.state.proximity.index or 2
        local isTalking = LocalPlayer.state.isTalking or false
        local voiceMode = "normal"
        local voicePercent = 0

        -- Determina o modo de voz e porcentagem
        if isTalking then
            if voiceLevel == 1 then       -- Sussurro
                voiceMode = "whisper"
                voicePercent = 30
            elseif voiceLevel == 2 then   -- Normal
                voiceMode = "normal"
                voicePercent = 60
            elseif voiceLevel == 3 then   -- Gritando
                voiceMode = "shout"
                voicePercent = 100
            end
        end

        -- Só envia atualização se o estado mudou
        if isTalking ~= lastTalkingState or voiceMode ~= lastVoiceMode then
            lastTalkingState = isTalking
            lastVoiceMode = voiceMode
            
            SendNUIMessage({
                action = "updateVoice",
                isTalking = isTalking,
                voiceMode = voiceMode,
                voicePercent = voicePercent
            })
        end
    end
end)