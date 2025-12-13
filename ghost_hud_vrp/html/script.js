let rotationInterval;
let currentConfig = {};
let hudElementsState = {};
let notificationQueue = [];
let isShowingNotification = false;

// =============================================
// SISTEMA DE VOZ
// =============================================
const voiceLevels = {
    whisper: { distance: 3.0, label: "Sussurro" },
    normal: { distance: 8.0, label: "Normal" },
    shout: { distance: 15.0, label: "Gritar" }
};
let currentVoiceLevel = "normal";
let isTalking = false;

function updateVoiceDisplay() {
    const voiceEl = document.getElementById("voice");
    if (!voiceEl) return;

    // Remove todas as classes de estado anterior
    voiceEl.classList.remove('voice-whisper', 'voice-normal', 'voice-shout', 'voice-talking');
    
    // Adiciona classe do nível atual
    voiceEl.classList.add(`voice-${currentVoiceLevel}`);
    
    // Adiciona classe se estiver falando
    if (isTalking) {
        voiceEl.classList.add('voice-talking');
    }

    // Atualiza texto do modo de voz
    const voiceModeEl = document.getElementById("voice-mode");
    if (voiceModeEl) {
        voiceModeEl.textContent = voiceLevels[currentVoiceLevel].label;
    }

    // Atualiza barra de voz (opcional)
    updateStatusFill('voice', isTalking ? 100 : 0);
}

// Allow multiple notifications (balões) simultaneously and respect caller duration.
function showNotification(title, message, type = 'info', duration) {
    // Determine final duration in ms:
    // - If duration is provided and >= 1000 assume milliseconds.
    // - If provided and < 1000 assume seconds and convert to ms.
    // - If not provided, fallback to a short default (3000ms) so notifications don't persist forever.
    let finalDuration;
    if (typeof duration !== 'undefined' && duration !== null) {
        if (Number(duration) >= 1000) finalDuration = Number(duration);
        else finalDuration = Number(duration) * 1000;
    } else {
        finalDuration = 3000; // minimal fallback — callers should provide their own duration
    }

    const notification = {
        title,
        message,
        type: type.toLowerCase(),
        duration: finalDuration
    };

    // Push to queue and try to display
    notificationQueue.push(notification);
    processNotificationQueue();
}

function processNotificationQueue() {
    const MAX_SIMULTANEOUS = 5;
    const container = document.getElementById('notification-container');
    if (!container) return;

    // Count active notifications on screen
    let active = container.querySelectorAll('.notification').length;

    // Fill up available slots
    while (notificationQueue.length > 0 && active < MAX_SIMULTANEOUS) {
        const { title, message, type, duration } = notificationQueue.shift();

        const notificationEl = document.createElement('div');
        notificationEl.className = `notification ${type}`;
        notificationEl.innerHTML = `
            <div class="notification-title">
                <i class="fas ${getNotificationIcon(type)}"></i>
                <span>${title}</span>
            </div>
            <div class="notification-message">${message}</div>
            <div class="notification-progress">
                <div class="notification-progress-bar"></div>
            </div>
        `;

        container.appendChild(notificationEl);
        active = active + 1;

        // Force reflow to start animation
        void notificationEl.offsetWidth;
        notificationEl.classList.add('show');

        // Progress bar
        const progressBar = notificationEl.querySelector('.notification-progress-bar');
        const startTime = Date.now();

        const updateProgress = () => {
            const elapsed = Date.now() - startTime;
            const remaining = Math.max(0, duration - elapsed);
            const percent = (remaining / duration) * 100;
            progressBar.style.width = `${percent}%`;
            if (remaining > 0) requestAnimationFrame(updateProgress);
        };
        updateProgress();

        // Remove afterwards
        setTimeout(() => {
            notificationEl.classList.remove('show');
            notificationEl.classList.add('hide');
            setTimeout(() => {
                notificationEl.remove();
            }, 300);
        }, duration);
    }
}

function getNotificationIcon(type) {
    const icons = {
        'success': 'fa-check-circle',
        'error': 'fa-times-circle',
        'warning': 'fa-exclamation-triangle',
        'info': 'fa-info-circle',
        // Tipos do Notify
        'negado': 'fa-ban',
        'aviso': 'fa-exclamation-circle',
        'sucesso': 'fa-check-circle',
        'policia': 'fa-shield-halved',
        'hospital': 'fa-truck-medical',
        'mecanica': 'fa-screwdriver-wrench'
    };
    return icons[type] || 'fa-info-circle';
}
// showNotification('Sucesso', 'Sua ação foi concluída com sucesso!', 'success');
// showNotification('Erro', 'Algo deu errado!', 'error');
// showNotification('Aviso', 'Isso é um aviso importante!', 'warning');
// showNotification('Informação', 'Esta é uma mensagem informativa.', 'info');


// =============================================
// FUNÇÕES ORIGINAIS (MANTIDAS SEM ALTERAÇÃO)
// =============================================
function updateClock() {
    fetch(`https://${GetParentResourceName()}/getGameTime`)
        .then(response => response.json())
        .then(data => {
            const hours = data.hours.toString().padStart(2, '0');
            const minutes = data.minutes.toString().padStart(2, '0');
            document.getElementById('time').textContent = `${hours}:${minutes}`;
            
            const clock = document.getElementById('clock');
            clock.classList.toggle('night-time', data.hours < 6 || data.hours >= 18);
        })
        .catch(error => console.error('Error fetching game time:', error));
}

setInterval(updateClock, 1000);
updateClock();

function setHealthBar(percent) {
    const healthBar = document.getElementById('health-bar-progress');
    const healthValue = document.getElementById('health-value');
    
    if (healthBar) {
        healthBar.style.width = `${percent}%`;
        
        if (percent <= 20) {
            healthBar.style.background = '#ff3e3e';
        } else if (percent <= 50) {
            healthBar.style.background = '#ffaa3e';
        } else {
            healthBar.style.background = 'linear-gradient(90deg, #ffffff, #f0f0f0)';
        }
    }
    
    if (healthValue) {
        healthValue.textContent = Math.round(percent);
        
        if (percent <= 50) {
            healthValue.style.color = 'white';
            healthValue.style.textShadow = '0 0 5px rgba(255, 0, 0, 0.8)';
        } else {
            healthValue.style.color = '#333';
            healthValue.style.textShadow = '0 1px 2px rgba(255, 255, 255, 0.5)';
        }
    }
}

function updateStatusValue(elementId, value) {
    const el = document.getElementById(elementId);
    if (el) el.textContent = Math.round(value);
}

function updateStatusFill(elementId, percent) {
    const icon = document.getElementById(elementId)?.querySelector('i');
    if (icon) {
        icon.style.setProperty('--fill-percent', `${percent}%`);
        
        if (percent > 0) {
            icon.classList.add('filled');
        } else {
            icon.classList.remove('filled');
        }
    }
}

// =============================================
// OUVINTE DE MENSAGENS
// =============================================
window.addEventListener('message', (event) => {
    const data = event.data;
    const logo = document.getElementById('logo');
    
    
    if (data.action === "updateStatus") {
        setHealthBar(data.health);
        updateStatusFill('armor', data.armor);
        updateStatusFill('hunger', data.hunger);
        updateStatusFill('thirst', data.thirst);
        updateStatusFill('stamina', data.stamina);
        updateStatusFill('stress', data.stress);
        updateStatusFill('voice', data.voicePercent);
        document.getElementById("job-name").textContent = data.job;
        document.getElementById("id-card-name").textContent = data.user_id;

        updateStatusValue('armor-value', data.armor);
        updateStatusValue('hunger-value', data.hunger);
        updateStatusValue('thirst-value', data.thirst);
        updateStatusValue('stamina-value', data.stamina);
        updateStatusValue('stress-value', data.stress);
        updateStatusValue('voice-value', data.voicePercent);
        
        // Atualiza voz (NOVO)
    if (data.voiceLevel !== undefined) {
        currentVoiceLevel = data.voiceLevel;
    }
    if (data.isTalking !== undefined) {
        isTalking = data.isTalking;
    }
    updateVoiceDisplay();
}

    if (data.action === "updateRadio") {
        const radioEl = document.getElementById("radio-hud");
        const frequencyEl = document.getElementById("radio-frequency");
        
        if (radioEl && frequencyEl) {
            frequencyEl.textContent = data.frequency || "OFF";
            if (data.show) {
                radioEl.classList.remove('hidden');
            } else {
                radioEl.classList.add('hidden');
            }
        }
    }

    if (event.data.action === "showNotification") {
        showNotification(event.data.title, event.data.message, event.data.type, event.data.duration);
    }

    if (data.action === "updateHUD") {
        currentConfig = data.config; 
        UpdateHUDPosition(data.config);
    }

        if (event.data.action === "vehicleHUD") {
        updateVehicleHud(event.data);
    }

    if (data.action === "updateStreet") {
        const streetElement = document.getElementById('street-name');
        if (streetElement) {
            streetElement.textContent = data.streetName;
        }
    }

    if (data.action === "updateWeapon") {
        const el = document.getElementById("weapon-hud");
        el.classList.remove("hidden");
        document.getElementById("ammo-clip").textContent = data.ammoClip;
        document.getElementById("ammo-inventory").textContent = data.ammoInventory;
    }
    
    if (data.action === "hideWeapon") {
        document.getElementById("weapon-hud").classList.add("hidden");
    }

    if (data.action === "updatePlayerData") {
  if (data.job !== undefined) {
        const jobElement = document.getElementById('job-name');
        if (jobElement) {
            jobElement.textContent = data.job;
        }
    }

        if (data.user_id !== undefined) {
            document.getElementById("id-card-name").textContent = data.user_id;
        }
    }
    if (event.data.action === "Notify") {
        const typeMap = {
            "negado": "error",
            "aviso": "warning",
            "sucesso": "success",
            "info": "info",
            "policia": "policia",
            "hospital": "hospital",
            "mecanica": "mecanica"
        };
        const notifyType = typeMap[event.data.type] || "info";

        // Support durations passed both in seconds or milliseconds.
        let msDuration = undefined;
        if (typeof event.data.time !== 'undefined' && event.data.time !== null) {
            const t = Number(event.data.time);
            if (!isNaN(t)) {
                msDuration = t >= 1000 ? t : t * 1000;
            }
        }

        showNotification(
            event.data.title || notifyType.toUpperCase(),
            event.data.message,
            notifyType,
            msDuration
        );
    }
});


function updateVehicleHud(data) {
    const el = document.getElementById("vehicle-hud");
    if (data.show) {
        el.classList.remove("hidden");
        
        // Velocidade
        document.getElementById("speed").textContent = data.speed;
        
        // RPM - Agulha do conta-giros (0-8)
        const rpmValue = data.rpm * 9; // Converte para escala 0-8
        const rpmAngle = -180 + (rpmValue * 33); // 45 graus por marca (0-8 = 360 graus)
        document.querySelector(".rpm-needle").style.transform = `translate(-50%, -100%) rotate(${rpmAngle}deg)`;
        
        // Combustível
        const fuelBar = document.getElementById("fuel-bar");
        if (fuelBar) {
            fuelBar.style.setProperty('--fuel-level', `${Math.round(data.fuel)}%`);
        }

        if (data.gear) {
            document.getElementById("gear-value").textContent = data.gear;
        }
        
        // Estado do motor e lataria
        const engineHealth = data.engineHealth || 100;
        const bodyHealth = data.bodyHealth || 100;
        document.getElementById("engine-health-bar").style.setProperty('--engine-health', `${engineHealth}%`);
        document.getElementById("body-health-bar").style.setProperty('--body-health', `${bodyHealth}%`);
        
        // Cinto e portas
        const cintoEl = document.getElementById("cinto-status");
        cintoEl.classList.toggle('on', data.cinto);
        cintoEl.classList.toggle('off', !data.cinto);
        
        const lockEl = document.getElementById("lock-status");
        lockEl.classList.toggle('locked', data.locked);
        lockEl.classList.toggle('unlocked', !data.locked);
    } else {
        el.classList.add("hidden");
    }
}

window.addEventListener('load', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ message: 'NUI is ready and loaded!' })
    }).then(() => {
        console.log("VRP_HUD: NUI Ready signal sent to client.");
    });
});

function UpdateHUDPosition(config) {
    if (!config) return;

    const hudContainer = document.getElementById('hud-container');
    if (!hudContainer) return;

    // Atualiza apenas o estado do HUD geral
    hudContainer.style.display = config.hudEnabled ? 'block' : 'none';
    
    // Atualiza cada elemento individualmente
    const elements = {
        'health': 'health-bar-container',
        'armor': 'armor',
        'hunger': 'hunger',
        'thirst': 'thirst',
        'stamina': 'stamina',
        'stress': 'stress',
        'voice': 'voice',
        'vehicle': 'vehicle-hud',
        'weapon': 'weapon-hud',
        'job': 'job',
        'id': 'id',
        'clock': 'clock'
    };

    Object.entries(elements).forEach(([key, id]) => {
        const element = document.getElementById(id);
        if (element) {
            const shouldShow = config.hudEnabled && 
                             (config.elements?.[key]?.enabled ?? true);
            element.style.display = shouldShow ? '' : 'none'; // Remove 'flex' para manter o CSS padrão
        }
    });

    // Atualiza o container do topo direito
    const topRightContainer = document.getElementById('topright-hud');
    if (topRightContainer) {
        const shouldShow = config.hudEnabled && 
                         ((config.elements?.job?.enabled ?? true) || 
                          (config.elements?.id?.enabled ?? true));
        topRightContainer.style.display = shouldShow ? 'flex' : 'none';
    }

    // Atualiza valores numéricos
    const showValues = config.showValues ?? true;
    document.querySelectorAll('.status-value').forEach(el => {
        el.style.display = showValues ? 'block' : 'none';
    });

    // Atualiza minimapa
    if (GetParentResourceName()) {
        fetch(`https://${GetParentResourceName()}/updateMinimap`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                show: config.hudEnabled && config.minimapEnabled 
            })
        }).catch(e => console.error('Error updating minimap:', e));
    }
}

function updateStreetName(streetName) {
    const streetElement = document.getElementById('street-name');
    if (streetElement) {
        streetElement.textContent = streetName;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const elements = document.querySelectorAll('.element-toggle');
    elements.forEach(el => {
        el.addEventListener('mouseenter', () => {
            el.style.backgroundColor = 'rgba(255, 255, 255, 0.1)';
        });
        el.addEventListener('mouseleave', () => {
            el.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
        });
    });
});