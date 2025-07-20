let isConfigOpen = false;

// Inicialização quando o DOM carrega
document.addEventListener('DOMContentLoaded', () => {
    initializeConfigEvents();
});

function initializeConfigEvents() {
    document.getElementById('close-config').addEventListener('click', CloseConfig);

    // Configura evento de tecla ESC
    document.addEventListener('keydown', (e) => {
        if (e.key === "Escape") {
            if (isConfigOpen) {
                CloseConfig();
            }
        }
    });
}

function OpenConfig(config) {
    currentConfig = JSON.parse(JSON.stringify(config));
    const panel = document.getElementById('config-panel');
    
    // Mostra o painel independente do estado da HUD
    panel.classList.remove('hidden');
    isConfigOpen = true;
    
    // Ativa pointer events apenas no painel de config
    panel.style.pointerEvents = 'all';
    document.getElementById('hud-container').style.pointerEvents = 'none';

    buildConfigInterface();
}

function buildConfigInterface() {
    const elementsList = document.getElementById('elements-list');
    elementsList.innerHTML = '';

    const toggleAllBtn = document.createElement('div');
    toggleAllBtn.id = 'toggle-all-btn';
    toggleAllBtn.className = 'control-center-item';
    toggleAllBtn.innerHTML = `
        <div class="control-center-icon">
            <i class="fas fa-power-off"></i>
        </div>
        <span class="control-center-label"></span>`;
    toggleAllBtn.addEventListener('click', DisableAllElements);
    elementsList.appendChild(toggleAllBtn);

    // Seção Controles Principais
    addSectionTitle('Controles Principais');
    addConfigToggle('showValues', 'Mostrar Valores', 'list-ol', currentConfig.showValues);
    addConfigToggle('minimapEnabled', 'Minimapa', 'map-marker-alt', currentConfig.minimapEnabled);

    // Seção Elementos da HUD
    addSectionTitle('Elementos da HUD');
    
    const elements = [
        {id: 'health', name: 'Barra de Vida', icon: 'heart'},
        {id: 'armor', name: 'Armadura', icon: 'shield-alt'},
        {id: 'hunger', name: 'Fome', icon: 'hamburger'},
        {id: 'thirst', name: 'Sede', icon: 'tint'},
        {id: 'stamina', name: 'Estamina', icon: 'running'},
        {id: 'stress', name: 'Estresse', icon: 'brain'},
        {id: 'voice', name: 'Voz', icon: 'microphone'},
        {id: 'vehicle', name: 'HUD do Veículo', icon: 'car'},
        {id: 'weapon', name: 'HUD da Arma', icon: 'crosshairs'},
        {id: 'coupon', name: 'Cupom', icon: 'ticket-alt'},
        {id: 'job', name: 'Trabalho', icon: 'briefcase'},
        {id: 'id', name: 'ID', icon: 'id-card'},
        {id: 'clock', name: 'Relógio', icon: 'clock'}
    ];

    elements.forEach(element => {
        if (currentConfig.elements[element.id] !== undefined) {
            addConfigToggle(
                element.id, 
                element.name, 
                element.icon, 
                currentConfig.elements[element.id].enabled,
                true
            );
        }
    });
    updateDisableAllButtonState(); 
}

function addConfigToggle(id, label, icon, isChecked, isElement = false) {
    const toggle = document.createElement('div');
    toggle.className = 'control-center-item';
    toggle.dataset.element = id;
    toggle.innerHTML = `
        <div class="control-center-icon">
            <i class="fas fa-${icon}"></i>
        </div>
        <span class="control-center-label">${label}</span>
        <label class="control-center-switch">
            <input type="checkbox" ${isChecked ? 'checked' : ''}>
            <span class="slider round"></span>
        </label>
    `;

    const input = toggle.querySelector('input');
    input.addEventListener('change', () => {
        if (isElement) {
            currentConfig.elements[id].enabled = input.checked;
        } else {
            currentConfig[id] = input.checked;
        }
        
        SaveConfig();
        UpdateHUDPosition(currentConfig);
    });

    document.getElementById('elements-list').appendChild(toggle);
}

function addSectionTitle(title) {
    const titleEl = document.createElement('div');
    titleEl.className = 'config-section-title';
    titleEl.textContent = title;
    document.getElementById('elements-list').appendChild(titleEl);
}

function updateDisableAllButtonState() {
    const button = document.getElementById('toggle-all-btn');
    if (!button) return;

    const label = button.querySelector('.control-center-label');
    const hudIsEnabled = currentConfig.hudEnabled;

    if (hudIsEnabled) {
        label.textContent = 'Desativar HUD';
        button.classList.remove('enable-all-btn');
        button.classList.add('disable-all-btn');
    } else {
        label.textContent = 'Ativar HUD';
        button.classList.remove('disable-all-btn');
        button.classList.add('enable-all-btn');
    }
}

function DisableAllElements() {
    const isCurrentlyEnabled = currentConfig.hudEnabled;
    currentConfig.hudEnabled = !isCurrentlyEnabled;

    Object.keys(currentConfig.elements).forEach(key => {
        if (currentConfig.elements[key]) {
            currentConfig.elements[key].enabled = currentConfig.hudEnabled;
        }
    });

    currentConfig.showValues = currentConfig.hudEnabled;
    currentConfig.minimapEnabled = currentConfig.hudEnabled;

    SaveConfig();
    UpdateHUDPosition(currentConfig);
    updateAllSwitches();
    updateDisableAllButtonState();
}

function updateAllSwitches() {
    document.querySelectorAll('.control-center-switch input').forEach(input => {
        const item = input.closest('.control-center-item');
        const elementId = item.dataset.element;
        
        if (!elementId) return;

        let isChecked = false;
        if (currentConfig.elements[elementId] !== undefined) {
            isChecked = currentConfig.elements[elementId].enabled;
        } else {
            isChecked = currentConfig[elementId];
        }
        
        input.checked = isChecked;
    });
}

function CloseConfig() {
    const panel = document.getElementById('config-panel');
    panel.classList.add('hidden');
    isConfigOpen = false;
    
    document.getElementById('hud-container').style.pointerEvents = 'none';
    
    fetch(`https://${GetParentResourceName()}/closeConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}

function SaveConfig() {
    fetch(`https://${GetParentResourceName()}/saveConfig`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            config: currentConfig
        })
    });
}

// Comunicação NUI
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openConfig' || data.action === 'forceShowConfig') {
        if (data.config) {
            OpenConfig(data.config);
        }
    }
});