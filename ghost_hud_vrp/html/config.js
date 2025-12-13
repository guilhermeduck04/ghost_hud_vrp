// config.js - SIMPLIFICADO

let isConfigOpen = false;
let localConfig = {};

function OpenConfig(config) {
    if (!config) return;
    
    localConfig = JSON.parse(JSON.stringify(config)); 
    
    const panel = document.getElementById('config-panel');
    panel.classList.remove('hidden');
    isConfigOpen = true;
    
    buildConfigInterface();
}

function CloseConfig() {
    document.getElementById('config-panel').classList.add('hidden');
    isConfigOpen = false;
    
    fetch(`https://${GetParentResourceName()}/closeConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(() => {
        SetNuiFocus(false, false);
    });
}

function SetNuiFocus(hasKeyboard, hasMouse) {
    fetch(`https://${GetParentResourceName()}/setNuiFocus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            hasKeyboard: hasKeyboard,
            hasMouse: hasMouse
        })
    });
}

function SaveConfig() {
    fetch(`https://${GetParentResourceName()}/saveConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config: localConfig })
    });
}

function buildConfigInterface() {
    const container = document.getElementById('elements-list');
    container.innerHTML = '';

    addSectionTitle('Controles Principais', container);
    addConfigToggle('hudEnabled', 'HUD Geral', 'fa-eye', container, false);
    addConfigToggle('minimapEnabled', 'Minimapa', 'fa-map-location-dot', container, false);
    addConfigToggle('showValues', 'Mostrar Valores', 'fa-percentage', container, false);

    addSectionTitle('Elementos da HUD', container);
    
    // Ordem dos elementos e garantia de que todos existem na configuração
    const elements = [
        {id: 'health', name: 'Vida', icon: 'fa-heart'},
        {id: 'armor', name: 'Colete', icon: 'fa-shield-alt'},
        // {id: 'hunger', name: 'Fome', icon: 'fa-hamburger'},
        // {id: 'thirst', name: 'Sede', icon: 'fa-tint'},
        {id: 'stamina', name: 'Estamina', icon: 'fa-person-running'},
        // {id: 'stress', name: 'Estresse', icon: 'fa-brain'},
        {id: 'voice', name: 'Voz', icon: 'fa-microphone'},
        {id: 'vehicle', name: 'HUD Veículo', icon: 'fa-car'},
        {id: 'weapon', name: 'HUD Arma', icon: 'fa-crosshairs'},
        {id: 'job', name: 'Emprego', icon: 'fa-briefcase'},
        {id: 'id', name: 'ID', icon: 'fa-id-card'},
        {id: 'coupon', name: 'Cupom', icon: 'fas fa-ticket-alt'},
        {id: 'clock', name: 'Relógio/Rua', icon: 'fa-clock'}
    ];

    // Garante que todos os elementos existam na configuração
    elements.forEach(el => {
        if (!localConfig.elements?.[el.id]) {
            if (!localConfig.elements) localConfig.elements = {};
            localConfig.elements[el.id] = { enabled: true };
        }
        addConfigToggle(el.id, el.name, el.icon, container, true);
    });

    updateTogglesState();
}

function addSectionTitle(title, container) {
    const titleEl = document.createElement('h2');
    titleEl.className = 'config-section-title';
    titleEl.textContent = title;
    container.appendChild(titleEl);
}

function addConfigToggle(key, label, icon, container, isElement) {
    const isChecked = isElement ? (localConfig.elements?.[key]?.enabled ?? true) : (localConfig[key] ?? true);
    
    const item = document.createElement('div');
    item.className = 'control-center-item';
    item.innerHTML = `
        <div class="control-center-icon"><i class="fas ${icon}"></i></div>
        <span class="control-center-label">${label}</span>
        <label class="control-center-switch">
            <input type="checkbox" data-key="${key}" data-element="${isElement}" ${isChecked ? 'checked' : ''}>
            <span class="slider"></span>
        </label>`;
    
    const checkbox = item.querySelector('input');
    checkbox.addEventListener('change', () => handleToggleChange(checkbox));
    container.appendChild(item);
}

function handleToggleChange(checkbox) {
    const key = checkbox.dataset.key;
    const isElement = checkbox.dataset.element === 'true';
    const isChecked = checkbox.checked;

    // Atualiza a configuração local corretamente
    if (isElement) {
        if (!localConfig.elements) localConfig.elements = {};
        if (!localConfig.elements[key]) localConfig.elements[key] = {};
        localConfig.elements[key].enabled = isChecked;
    } else {
        localConfig[key] = isChecked;
    }

    // Atualiza apenas o elemento modificado
    if (typeof UpdateHUDPosition === 'function') {
        UpdateHUDPosition(localConfig);
    }

    // Atualiza estado dos toggles
    updateTogglesState();
    
    // Salva no servidor
    SaveConfig();
}

function updateTogglesState() {
    const hudEnabled = localConfig.hudEnabled;
    document.querySelectorAll('#elements-list input[type="checkbox"]').forEach(toggle => {
        if (toggle.dataset.key !== 'hudEnabled') {
            toggle.disabled = !hudEnabled;
        }
    });
}

window.addEventListener('message', (event) => {
    if (event.data.action === "openConfig") {
        OpenConfig(event.data.config);
    }
});

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('close-config')?.addEventListener('click', CloseConfig);
});
document.addEventListener('keydown', (e) => {
    if (e.key === "Escape" && isConfigOpen) CloseConfig();
});