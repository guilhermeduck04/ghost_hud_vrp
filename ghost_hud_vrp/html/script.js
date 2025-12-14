let currentConfig = {};
let notificationQueue = [];
let isEditMode = false;
let draggedElement = null;
let savedPositions = {};

// =============================================
// SISTEMA DE VOZ E STATUS
// =============================================
const voiceLevels = {
    whisper: { label: "Sussurro" },
    normal: { label: "Normal" },
    shout: { label: "Gritar" }
};
let currentVoiceLevel = "normal";
let isTalking = false;

function updateVoiceDisplay() {
    const voiceEl = document.getElementById("voice");
    if (!voiceEl) return;

    voiceEl.classList.remove('voice-whisper', 'voice-normal', 'voice-shout', 'voice-talking');
    voiceEl.classList.add(`voice-${currentVoiceLevel}`);
    
    if (isTalking) {
        voiceEl.classList.add('voice-talking');
    }

    const voiceModeEl = document.getElementById("voice-mode");
    if (voiceModeEl) {
        voiceModeEl.textContent = voiceLevels[currentVoiceLevel]?.label || "Normal";
    }
    
    // Atualiza preenchimento visual
    updateStatusFill('voice', isTalking ? 100 : 30); 
}

// =============================================
// SISTEMA DE NOTIFICAÇÃO
// =============================================
function showNotification(title, message, type = 'info', duration) {
    let finalDuration = duration;
    if (!finalDuration) finalDuration = 3000;
    else if (finalDuration < 1000) finalDuration *= 1000;

    const notification = { title, message, type: type.toLowerCase(), duration: finalDuration };
    notificationQueue.push(notification);
    processNotificationQueue();
}

function processNotificationQueue() {
    const MAX_SIMULTANEOUS = 5;
    const container = document.getElementById('notification-container');
    if (!container) return;

    let active = container.querySelectorAll('.notification').length;

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
        active++;

        // Força reflow para animação
        void notificationEl.offsetWidth;
        notificationEl.classList.add('show');

        // Barra de progresso
        const progressBar = notificationEl.querySelector('.notification-progress-bar');
        progressBar.style.transition = `width ${duration}ms linear`;
        
        // Timeout pequeno para garantir que a transição CSS pegue
        setTimeout(() => {
            progressBar.style.width = '0%';
        }, 50);

        // Remover
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
        'policia': 'fa-shield-halved',
        'hospital': 'fa-truck-medical',
        'mecanica': 'fa-screwdriver-wrench'
    };
    return icons[type] || 'fa-info-circle';
}

// =============================================
// ATUALIZAÇÃO DE DADOS (STATUS/VEÍCULO)
// =============================================
function setHealthBar(percent) {
    const healthBar = document.getElementById('health-bar-progress');
    const healthValue = document.getElementById('health-value');
    
    if (healthBar) {
        healthBar.style.width = `${percent}%`;
        if (percent <= 20) healthBar.style.background = '#ff3e3e';
        else if (percent <= 50) healthBar.style.background = '#ffaa3e';
        else healthBar.style.background = 'linear-gradient(90deg, #ffffff, #f0f0f0)';
    }
    
    if (healthValue) {
        healthValue.textContent = Math.round(percent);
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
        if (percent > 0) icon.classList.add('filled');
        else icon.classList.remove('filled');
    }
}

function updateVehicleHud(data) {
    const el = document.getElementById("vehicle-hud");
    
    // Se estiver em modo edição, sempre mostra para poder arrastar
    if (data.show || isEditMode) {
        el.classList.remove("hidden");
        
        document.getElementById("speed").textContent = data.speed || 0;
        
        // RPM
        const rpmValue = (data.rpm || 0) * 9;
        const rpmAngle = -180 + (rpmValue * 33);
        const needle = document.querySelector(".rpm-needle");
        if(needle) needle.style.transform = `translate(-50%, -100%) rotate(${rpmAngle}deg)`;
        
        // Status do Veículo
        const fuelBar = document.getElementById("fuel-bar");
        if (fuelBar) fuelBar.style.setProperty('--fuel-level', `${Math.round(data.fuel || 0)}%`);

        if (data.gear) document.getElementById("gear-value").textContent = data.gear;
        
        document.getElementById("engine-health-bar").style.setProperty('--engine-health', `${data.engineHealth || 100}%`);
        document.getElementById("body-health-bar").style.setProperty('--body-health', `${data.bodyHealth || 100}%`);
        
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

// =============================================
// DRAG & DROP E POSICIONAMENTO
// =============================================

function enableEditMode() {
    isEditMode = true;
    document.getElementById('hud-container').classList.add('edit-mode');
    document.getElementById('edit-controls').classList.remove('hidden');
    document.getElementById('config-panel').classList.add('hidden'); // Fecha config
    
    // Força mostrar elementos ocultos para poder editar
    document.getElementById('vehicle-hud').classList.remove('hidden');
    document.getElementById('weapon-hud').classList.remove('hidden');
    document.getElementById('radio-hud').classList.remove('hidden');

    // Notifica client para dar foco total
    fetch(`https://${GetParentResourceName()}/setEditMode`, {
        method: 'POST',
        body: JSON.stringify({ enabled: true })
    });
}

function disableEditMode(save) {
    isEditMode = false;
    document.getElementById('hud-container').classList.remove('edit-mode');
    document.getElementById('edit-controls').classList.add('hidden');
    
    // Volta a esconder se necessário (o loop do client vai corrigir no proximo tick, mas forçamos visualmente)
    // O client enviará updates logo em seguida corrigindo a visibilidade real

    if (save) {
        saveLayout();
    } else {
        loadLayout(savedPositions); // Reverte
    }

    // Tira foco
    fetch(`https://${GetParentResourceName()}/setEditMode`, {
        method: 'POST',
        body: JSON.stringify({ enabled: false })
    });
}

function makeDraggable() {
    const draggables = document.querySelectorAll('.hud-draggable');
    
    draggables.forEach(elmnt => {
        let pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
        
        elmnt.onmousedown = dragMouseDown;

        function dragMouseDown(e) {
            if (!isEditMode) return;
            e = e || window.event;
            e.preventDefault();
            pos3 = e.clientX;
            pos4 = e.clientY;
            document.onmouseup = closeDragElement;
            document.onmousemove = elementDrag;
        }

        function elementDrag(e) {
            e = e || window.event;
            e.preventDefault();
            // Calcula nova posição
            pos1 = pos3 - e.clientX;
            pos2 = pos4 - e.clientY;
            pos3 = e.clientX;
            pos4 = e.clientY;
            
            // Define top/left em pixels
            let newTop = (elmnt.offsetTop - pos2);
            let newLeft = (elmnt.offsetLeft - pos1);
            
            // Converte para porcentagem para ser responsivo
            let percentTop = (newTop / window.innerHeight) * 100;
            let percentLeft = (newLeft / window.innerWidth) * 100;

            elmnt.style.top = percentTop + "%";
            elmnt.style.left = percentLeft + "%";
            elmnt.style.bottom = "auto";
            elmnt.style.right = "auto";
            elmnt.style.transform = "none"; // Remove transforms que centralizam
        }

        function closeDragElement() {
            document.onmouseup = null;
            document.onmousemove = null;
        }
    });
}

function saveLayout() {
    const layout = {};
    document.querySelectorAll('.hud-draggable').forEach(el => {
        const id = el.dataset.id;
        layout[id] = {
            top: el.style.top,
            left: el.style.left,
            right: el.style.right,
            bottom: el.style.bottom
        };
    });
    
    // Atualiza cache local
    savedPositions = layout;

    // Envia para client salvar KVPs
    fetch(`https://${GetParentResourceName()}/saveLayout`, {
        method: 'POST',
        body: JSON.stringify({ layout: layout })
    });
}

function loadLayout(layout) {
    if (!layout) return;
    savedPositions = layout; // Guarda backup

    Object.keys(layout).forEach(key => {
        const el = document.querySelector(`.hud-draggable[data-id="${key}"]`);
        if (el && layout[key]) {
            el.style.top = layout[key].top || "auto";
            el.style.left = layout[key].left || "auto";
            el.style.right = layout[key].right || "auto";
            el.style.bottom = layout[key].bottom || "auto";
            
            // Se tiver posição salva, remove transform padrão de centralização se existir
            if(layout[key].top || layout[key].left) {
                el.style.transform = "none";
            }
        }
    });
}

function resetLayout() {
    fetch(`https://${GetParentResourceName()}/resetLayout`, { method: 'POST', body: JSON.stringify({}) });
    // Remove estilos inline para voltar ao CSS original
    document.querySelectorAll('.hud-draggable').forEach(el => {
        el.style.top = "";
        el.style.left = "";
        el.style.right = "";
        el.style.bottom = "";
        el.style.transform = "";
    });
    savedPositions = {};
}

// =============================================
// LISTENERS
// =============================================
window.addEventListener('load', () => {
    makeDraggable();
    
    // Botões de controle de edição
    document.getElementById('btn-save-edit').addEventListener('click', () => disableEditMode(true));
    document.getElementById('btn-cancel-edit').addEventListener('click', () => disableEditMode(false));
    
    // Botões dentro do config
    document.getElementById('btn-edit-mode').addEventListener('click', enableEditMode);
    document.getElementById('btn-reset-layout').addEventListener('click', resetLayout);

    fetch(`https://${GetParentResourceName()}/nuiReady`, {
        method: 'POST',
        body: JSON.stringify({ message: 'Ready' })
    });
});

window.addEventListener('message', (event) => {
    const data = event.data;

    // Toggle geral (ESC/Garagem)
    if (data.action === "toggleHUD") {
        const container = document.getElementById('hud-container');
        if (data.show) {
            container.style.display = 'block';
            container.style.opacity = '1';
        } else {
            // Se estiver em modo edição, não esconde
            if (!isEditMode) {
                container.style.opacity = '0';
                setTimeout(() => { if(!isEditMode) container.style.display = 'none'; }, 200);
            }
        }
    }

    if (data.action === "updateStatus") {
        setHealthBar(data.health);
        updateStatusFill('armor', data.armor);
        updateStatusFill('hunger', data.hunger);
        updateStatusFill('thirst', data.thirst);
        updateStatusFill('stamina', data.stamina);
        updateStatusFill('stress', data.stress);
        updateStatusFill('voice', 100); // Voz sempre cheia, muda a cor
        
        if (data.job) document.getElementById("job-name").textContent = data.job;
        if (data.user_id) document.getElementById("id-card-name").textContent = data.user_id;

        updateStatusValue('armor-value', data.armor);
        updateStatusValue('hunger-value', data.hunger);
        updateStatusValue('thirst-value', data.thirst);
        updateStatusValue('stamina-value', data.stamina);
        updateStatusValue('stress-value', data.stress);

        if (data.voiceLevel) currentVoiceLevel = data.voiceLevel;
        if (data.isTalking !== undefined) isTalking = data.isTalking;
        updateVoiceDisplay();
    }

    if (data.action === "vehicleHUD") updateVehicleHud(data);

    if (data.action === "updateWeapon") {
        const el = document.getElementById("weapon-hud");
        // Só atualiza se não estiver editando (em edição ele é forçado visível)
        if(!isEditMode) el.classList.remove("hidden");
        
        document.getElementById("ammo-clip").textContent = data.ammoClip;
        document.getElementById("ammo-inventory").textContent = data.ammoInventory;
    }
    
    if (data.action === "hideWeapon") {
        if(!isEditMode) document.getElementById("weapon-hud").classList.add("hidden");
    }

    if (data.action === "updateStreet") {
        const el = document.getElementById('street-name');
        if (el) el.textContent = data.streetName;
    }

    if (data.action === "getGameTime") {
        const hours = data.hours.toString().padStart(2, '0');
        const minutes = data.minutes.toString().padStart(2, '0');
        document.getElementById('time').textContent = `${hours}:${minutes}`;
    }

    if (data.action === "showNotification") {
        showNotification(data.title, data.message, data.type, data.duration);
    }

    if (data.action === "loadLayout") {
        loadLayout(data.layout);
    }
    
    // Atualização de configuração (Toggles)
    if (data.action === "updateHUD") {
        if (data.config) {
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
                'coupon': 'coupon',
                'clock': 'clock'
            };

            // Atualiza visibilidade baseada na config
            // Nota: Se isEditMode for true, ignoramos isso para mostrar tudo
            if (!isEditMode) {
                Object.entries(elements).forEach(([key, id]) => {
                    const el = document.getElementById(id);
                    if (el) {
                        const enabled = data.config.elements?.[key]?.enabled ?? true;
                        el.style.display = enabled ? '' : 'none';
                    }
                });
                
                // Toggle Geral
                if (data.config.hudEnabled !== undefined) {
                    const hud = document.getElementById('hud-container');
                    hud.style.display = data.config.hudEnabled ? 'block' : 'none';
                }
            }
        }
    }
});