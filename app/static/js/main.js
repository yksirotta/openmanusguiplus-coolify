// Main JavaScript for OpenManus Web UI Dashboard

document.addEventListener('DOMContentLoaded', function () {
    // Initialize the UI
    initializeUI();

    // Set up event listeners
    setupEventListeners();

    // Auto-resize textarea
    const userInput = document.getElementById('user-input');
    if (userInput) {
        userInput.addEventListener('input', autoResizeTextarea);
    }
});

// Initialize UI components
function initializeUI() {
    // Check for preferred theme
    const prefersDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    const savedTheme = localStorage.getItem('theme') || (prefersDarkMode ? 'dark' : 'light');
    setTheme(savedTheme);

    // Initialize tooltips, popovers, etc.
    initTooltips();

    // Set up visualization panels if available
    initVisualization();

    // Show welcome message animation
    animateWelcomeMessage();
}

// Set up event listeners for UI interactions
function setupEventListeners() {
    // Theme toggle
    const themeToggle = document.querySelector('.theme-toggle');
    if (themeToggle) {
        themeToggle.addEventListener('click', toggleTheme);
    }

    // Send button
    const sendButton = document.getElementById('send-button');
    if (sendButton) {
        sendButton.addEventListener('click', handleSendMessage);
    }

    // User input form - handle enter key
    const userInput = document.getElementById('user-input');
    if (userInput) {
        userInput.addEventListener('keydown', function (e) {
            // Send on Enter (without Shift)
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSendMessage();
            }
        });
    }

    // Suggested actions
    const actionButtons = document.querySelectorAll('.action-btn');
    actionButtons.forEach(btn => {
        btn.addEventListener('click', function () {
            const action = this.dataset.action;
            handleSuggestedAction(action);
        });
    });

    // Tool options
    const toolOptions = document.querySelectorAll('.tool-option');
    toolOptions.forEach(option => {
        option.addEventListener('click', function () {
            const tool = this.dataset.tool;
            activateTool(tool);
        });
    });

    // Tool sidebar toggle
    const toolToggle = document.querySelector('.toggle-tools');
    if (toolToggle) {
        toolToggle.addEventListener('click', toggleToolsSidebar);
    }

    // Visualization panel toggle
    document.querySelectorAll('.close-viz').forEach(btn => {
        btn.addEventListener('click', toggleVisualizationPanel);
    });

    // Tab switching in visualization panel
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            const tabId = this.dataset.tab;
            switchTab(tabId);
        });
    });

    // Context items removal
    document.querySelectorAll('.context-item button').forEach(btn => {
        btn.addEventListener('click', function () {
            removeContextItem(this.parentNode);
        });
    });

    // Modal close buttons
    document.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', closeModal);
    });

    // Settings button
    const settingsButton = document.querySelector('li a[href="#"][title="Settings"], .sidebar-nav a[href="#"]:has(i.fas.fa-cog)');
    if (settingsButton) {
        settingsButton.addEventListener('click', openSettingsModal);
    }
}

// Handle sending a user message
function handleSendMessage() {
    const userInput = document.getElementById('user-input');
    const message = userInput.value.trim();

    if (message === '') return;

    // Add user message to the conversation
    addUserMessage(message);

    // Clear the input
    userInput.value = '';
    userInput.style.height = 'auto';

    // Send to the AI and display thinking indicator
    showThinkingIndicator();

    // Simulate AI response after a brief delay (would be replaced with actual API call)
    setTimeout(() => {
        // Remove thinking indicator
        removeThinkingIndicator();

        // Simulate AI response
        const aiResponse = "I've received your message. In a real implementation, this would be processed by the OpenManus AI backend.";
        addAIMessage(aiResponse);

        // Scroll to bottom of conversation
        scrollConversationToBottom();
    }, 1500);
}

// Add a user message to the conversation
function addUserMessage(message) {
    const conversation = document.getElementById('conversation');

    // Create message HTML
    const messageHTML = `
        <div class="message user">
            <div class="message-avatar">
                <img src="${getBasePath()}/static/img/profile.jpg" alt="User">
            </div>
            <div class="message-content">
                <div class="message-header">
                    <span class="message-sender">You</span>
                    <span class="message-time">${getCurrentTime()}</span>
                </div>
                <div class="message-text">
                    <p>${formatMessage(message)}</p>
                </div>
            </div>
            <div class="message-controls">
                <button class="btn btn-transparent btn-sm"><i class="fas fa-edit"></i></button>
                <button class="btn btn-transparent btn-sm"><i class="fas fa-ellipsis-v"></i></button>
            </div>
        </div>
    `;

    // Add to conversation
    conversation.insertAdjacentHTML('beforeend', messageHTML);

    // Scroll to bottom of conversation
    scrollConversationToBottom();
}

// Add an AI message to the conversation
function addAIMessage(message, richContent = null) {
    const conversation = document.getElementById('conversation');

    // Create message HTML
    let messageHTML = `
        <div class="message assistant">
            <div class="message-avatar">
                <img src="${getBasePath()}/static/img/assistant-avatar.png" alt="Assistant">
            </div>
            <div class="message-content">
                <div class="message-header">
                    <span class="message-sender">OpenManus AI</span>
                    <span class="message-time">${getCurrentTime()}</span>
                </div>
                <div class="message-text">
                    <p>${formatMessage(message)}</p>
                    ${richContent || ''}
                </div>
            </div>
            <div class="message-controls">
                <button class="btn btn-transparent btn-sm"><i class="fas fa-copy"></i></button>
                <button class="btn btn-transparent btn-sm"><i class="fas fa-thumbs-up"></i></button>
                <button class="btn btn-transparent btn-sm"><i class="fas fa-thumbs-down"></i></button>
                <button class="btn btn-transparent btn-sm"><i class="fas fa-ellipsis-v"></i></button>
            </div>
        </div>
    `;

    // Add to conversation
    conversation.insertAdjacentHTML('beforeend', messageHTML);

    // Scroll to bottom of conversation
    scrollConversationToBottom();
}

// Show the "AI is thinking" indicator
function showThinkingIndicator() {
    const conversation = document.getElementById('conversation');

    // Create thinking indicator HTML
    const thinkingHTML = `
        <div class="message assistant thinking">
            <div class="message-avatar">
                <img src="${getBasePath()}/static/img/assistant-avatar.png" alt="Assistant">
            </div>
            <div class="message-content">
                <div class="message-header">
                    <span class="message-sender">OpenManus AI</span>
                    <span class="message-time">Now</span>
                </div>
                <div class="message-text">
                    <div class="typing-indicator">
                        <span></span>
                        <span></span>
                        <span></span>
                    </div>
                </div>
            </div>
        </div>
    `;

    // Add to conversation
    conversation.insertAdjacentHTML('beforeend', thinkingHTML);

    // Scroll to bottom of conversation
    scrollConversationToBottom();
}

// Remove the thinking indicator
function removeThinkingIndicator() {
    const thinkingIndicator = document.querySelector('.message.thinking');
    if (thinkingIndicator) {
        thinkingIndicator.remove();
    }
}

// Format message text with links and code
function formatMessage(text) {
    // Convert URLs to clickable links
    text = text.replace(/(https?:\/\/[^\s]+)/g, '<a href="$1" target="_blank">$1</a>');

    // Convert code blocks with ```
    text = text.replace(/```([^`]+)```/g, '<pre><code>$1</code></pre>');

    // Convert inline code with `
    text = text.replace(/`([^`]+)`/g, '<code>$1</code>');

    return text;
}

// Auto-resize textarea as user types
function autoResizeTextarea() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
}

// Get current time in HH:MM format
function getCurrentTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
}

// Scroll conversation to the bottom
function scrollConversationToBottom() {
    const conversation = document.getElementById('conversation');
    conversation.scrollTop = conversation.scrollHeight;
}

// Toggle between light and dark theme
function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';

    setTheme(newTheme);
}

// Set the theme
function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);

    // Update theme toggle icon
    const themeToggle = document.querySelector('.theme-toggle i');
    if (themeToggle) {
        if (theme === 'dark') {
            themeToggle.classList.remove('fa-moon');
            themeToggle.classList.add('fa-sun');
        } else {
            themeToggle.classList.remove('fa-sun');
            themeToggle.classList.add('fa-moon');
        }
    }
}

// Handle suggested action button clicks
function handleSuggestedAction(action) {
    let message = '';

    switch (action) {
        case 'web-search':
            message = 'Search the web for information about OpenManus capabilities';
            break;
        case 'file-analysis':
            message = 'Can you help me analyze a Python file?';
            break;
        case 'coding':
            message = 'Help me write a script to automate browser tasks';
            break;
        case 'brainstorm':
            message = 'Let\'s brainstorm ideas for using AI agents in my workflow';
            break;
        default:
            message = 'I want to try the ' + action + ' feature';
    }

    // Set the message in the input field
    const userInput = document.getElementById('user-input');
    userInput.value = message;

    // Focus on the input for user to edit if needed
    userInput.focus();
}

// Activate a specific tool
function activateTool(tool) {
    // Close the tools dropdown
    const toolsDropdown = document.querySelector('.tools-dropdown');
    if (toolsDropdown) {
        toolsDropdown.style.display = 'none';
    }

    // Show visualization panel for certain tools
    if (['code-editor', 'terminal', 'debugger'].includes(tool)) {
        showVisualizationPanel();
    }

    // Add context item for the tool
    addContextItem(tool);

    // Handle specific tool actions
    switch (tool) {
        case 'web-search':
            promptWebSearch();
            break;
        case 'file-upload':
            triggerFileUpload();
            break;
        case 'code-run':
            showCodeEditor();
            break;
        // Add more tool handlers as needed
    }

    // Show toast notification
    showToast(`${capitalize(tool.replace('-', ' '))} tool activated`);
}

// Add an item to the context panel
function addContextItem(type) {
    const contextItems = document.querySelector('.context-items');

    if (!contextItems) return;

    let icon, text;

    switch (type) {
        case 'web-search':
            icon = 'fa-globe';
            text = 'Web search active';
            break;
        case 'file-upload':
            icon = 'fa-file-upload';
            text = 'File upload ready';
            break;
        case 'code-run':
            icon = 'fa-code';
            text = 'Code execution environment';
            break;
        default:
            icon = 'fa-tools';
            text = capitalize(type.replace('-', ' '));
    }

    const itemHTML = `
        <div class="context-item" data-type="${type}">
            <i class="fas ${icon}"></i>
            <span>${text}</span>
            <button class="btn btn-transparent btn-sm"><i class="fas fa-times"></i></button>
        </div>
    `;

    contextItems.insertAdjacentHTML('beforeend', itemHTML);

    // Add event listener to the remove button
    const newItem = contextItems.lastElementChild;
    const removeBtn = newItem.querySelector('button');
    removeBtn.addEventListener('click', function () {
        removeContextItem(newItem);
    });
}

// Remove an item from the context panel
function removeContextItem(item) {
    item.classList.add('fade-out');

    setTimeout(() => {
        item.remove();
    }, 300);
}

// Show the visualization panel
function showVisualizationPanel() {
    const vizPanel = document.querySelector('.visualization-panel');
    if (vizPanel) {
        vizPanel.classList.remove('hidden');
    }
}

// Hide the visualization panel
function toggleVisualizationPanel() {
    const vizPanel = document.querySelector('.visualization-panel');
    if (vizPanel) {
        vizPanel.classList.toggle('hidden');
    }
}

// Switch tabs in the visualization panel
function switchTab(tabId) {
    // Remove active class from all tabs
    document.querySelectorAll('.tab-btn').forEach(tab => {
        tab.classList.remove('active');
    });

    // Hide all tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.add('hidden');
    });

    // Activate the selected tab
    document.querySelector(`.tab-btn[data-tab="${tabId}"]`).classList.add('active');
    document.getElementById(`${tabId}-tab`).classList.remove('hidden');
}

// Initialize the visualization panels
function initVisualization() {
    // This would be replaced with actual visualization code
    console.log('Visualization panels initialized');
}

// Show a web search prompt
function promptWebSearch() {
    const userInput = document.getElementById('user-input');
    userInput.value = 'Search the web for: ';
    userInput.focus();

    // Place cursor at the end
    userInput.setSelectionRange(userInput.value.length, userInput.value.length);
}

// Trigger file upload dialog
function triggerFileUpload() {
    // Create a file input
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.style.display = 'none';

    // Add onchange handler
    fileInput.onchange = function () {
        if (this.files && this.files[0]) {
            handleFileUpload(this.files[0]);
        }
    };

    // Append to body, trigger click, then remove
    document.body.appendChild(fileInput);
    fileInput.click();

    setTimeout(() => {
        document.body.removeChild(fileInput);
    }, 1000);
}

// Handle uploaded file
function handleFileUpload(file) {
    // Update context panel
    const contextItems = document.querySelector('.context-items');

    if (!contextItems) return;

    // Remove existing file upload item if exists
    const existingFileItem = document.querySelector('.context-item[data-type="file-upload"]');
    if (existingFileItem) {
        existingFileItem.remove();
    }

    // Add new file context item
    const itemHTML = `
        <div class="context-item" data-type="file-upload">
            <i class="fas fa-file"></i>
            <span>File: ${file.name}</span>
            <button class="btn btn-transparent btn-sm"><i class="fas fa-times"></i></button>
        </div>
    `;

    contextItems.insertAdjacentHTML('beforeend', itemHTML);

    // Add event listener to the remove button
    const newItem = contextItems.lastElementChild;
    const removeBtn = newItem.querySelector('button');
    removeBtn.addEventListener('click', function () {
        removeContextItem(newItem);
    });

    // Show toast notification
    showToast(`File "${file.name}" uploaded`);

    // In a real implementation, you would upload the file to the server here
    // and then reference it in the conversation
}

// Show code editor in visualization panel
function showCodeEditor() {
    showVisualizationPanel();

    // Switch to the proper tab if it exists
    const codeTab = document.querySelector('.tab-btn[data-tab="code"]');
    if (codeTab) {
        codeTab.click();
    } else {
        // If no dedicated code tab, show in the thinking tab as a fallback
        switchTab('thinking');

        // Replace placeholder with code editor
        const thinkingTab = document.getElementById('thinking-tab');
        if (thinkingTab) {
            thinkingTab.innerHTML = `
                <div class="code-editor-container">
                    <div class="editor-header">
                        <span>Code Editor</span>
                        <div class="editor-controls">
                            <button class="btn btn-transparent btn-sm"><i class="fas fa-play"></i> Run</button>
                            <button class="btn btn-transparent btn-sm"><i class="fas fa-save"></i> Save</button>
                        </div>
                    </div>
                    <textarea class="code-editor" placeholder="Write or paste your code here..."></textarea>
                </div>
            `;
        }
    }
}

// Toggle the tools sidebar
function toggleToolsSidebar() {
    const toolsSidebar = document.querySelector('.tools-sidebar');
    if (toolsSidebar) {
        toolsSidebar.classList.toggle('collapsed');
    }
}

// Open settings modal
function openSettingsModal() {
    const settingsModal = document.getElementById('settings-modal');
    if (settingsModal) {
        settingsModal.classList.add('visible');
    }
}

// Close the currently open modal
function closeModal() {
    document.querySelectorAll('.modal.visible').forEach(modal => {
        modal.classList.remove('visible');
    });
}

// Show a toast notification
function showToast(message, type = 'success') {
    const toastContainer = document.querySelector('.toast-container');

    if (!toastContainer) return;

    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    // Set icon based on type
    let icon = 'fa-check-circle';
    switch (type) {
        case 'error':
            icon = 'fa-exclamation-circle';
            break;
        case 'warning':
            icon = 'fa-exclamation-triangle';
            break;
        case 'info':
            icon = 'fa-info-circle';
            break;
    }

    // Set toast content
    toast.innerHTML = `
        <i class="fas ${icon}"></i>
        <span>${message}</span>
    `;

    // Add to container
    toastContainer.appendChild(toast);

    // Show the toast
    setTimeout(() => {
        toast.classList.add('visible');
    }, 10);

    // Hide after 3 seconds
    setTimeout(() => {
        toast.classList.remove('visible');

        // Remove from DOM after animation completes
        setTimeout(() => {
            toastContainer.removeChild(toast);
        }, 300);
    }, 3000);
}

// Initialize tooltips
function initTooltips() {
    // This would be replaced with actual tooltip initialization code
    console.log('Tooltips initialized');
}

// Animate the welcome message
function animateWelcomeMessage() {
    const welcomeMessage = document.querySelector('.message.assistant');
    if (welcomeMessage) {
        welcomeMessage.style.opacity = '0';
        welcomeMessage.style.transform = 'translateY(20px)';

        setTimeout(() => {
            welcomeMessage.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
            welcomeMessage.style.opacity = '1';
            welcomeMessage.style.transform = 'translateY(0)';
        }, 100);
    }
}

// Helper to get base path for assets
function getBasePath() {
    // This would be replaced with actual logic to get the base URL
    return '';
}

// Capitalize first letter of a string
function capitalize(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

// System Monitor functionality
let systemStatsInterval;
let cpuData = [];
let memoryData = [];
let cpuChart, memoryChart, diskChart;
const maxDataPoints = 20;

// Initialize system monitoring
function initSystemMonitor() {
    // Update the basic monitor on the sidebar
    updateBasicSystemStats();

    // Set up interval for continuous updates
    if (!systemStatsInterval) {
        systemStatsInterval = setInterval(updateBasicSystemStats, 5000);
    }

    // Set up detailed stats viewer
    const viewStatsBtn = document.getElementById('view-detailed-stats');
    if (viewStatsBtn) {
        viewStatsBtn.addEventListener('click', showSystemMonitorModal);
    }
}

// Update the basic system stats display
function updateBasicSystemStats() {
    fetch('/api/system/stats')
        .then(response => response.json())
        .then(data => {
            // Update CPU usage
            const cpuBar = document.getElementById('cpu-bar');
            const cpuValue = document.getElementById('cpu-value');
            if (cpuBar && cpuValue) {
                cpuBar.style.width = `${data.cpu.percent}%`;
                cpuValue.textContent = `${data.cpu.percent}%`;
            }

            // Update RAM usage
            const ramBar = document.getElementById('ram-bar');
            const ramValue = document.getElementById('ram-value');
            if (ramBar && ramValue) {
                ramBar.style.width = `${data.memory.percent}%`;
                ramValue.textContent = `${data.memory.percent}%`;
            }

            // Update Disk usage
            const diskBar = document.getElementById('disk-bar');
            const diskValue = document.getElementById('disk-value');
            if (diskBar && diskValue) {
                diskBar.style.width = `${data.disk.percent}%`;
                diskValue.textContent = `${data.disk.percent}%`;
            }
        })
        .catch(error => console.error('Error fetching system stats:', error));
}

// Show the detailed system monitor modal
function showSystemMonitorModal() {
    const modal = document.getElementById('system-monitor-modal');
    if (modal) {
        // Show the modal
        modal.classList.add('active');

        // Initialize charts if needed
        initSystemCharts();

        // Update stats immediately and start interval
        updateDetailedSystemStats();

        // Set up interval for continuous updates
        const detailedStatsInterval = setInterval(updateDetailedSystemStats, 2000);

        // Clear interval when modal is closed
        const closeButtons = modal.querySelectorAll('.close-modal');
        closeButtons.forEach(button => {
            button.addEventListener('click', () => {
                clearInterval(detailedStatsInterval);
                modal.classList.remove('active');
            });
        });
    }
}

// Initialize the system monitoring charts
function initSystemCharts() {
    const cpuCtx = document.getElementById('cpu-chart');
    const memoryCtx = document.getElementById('memory-chart');
    const diskCtx = document.getElementById('disk-chart');

    if (cpuCtx && !cpuChart) {
        cpuChart = new Chart(cpuCtx, {
            type: 'line',
            data: {
                labels: Array(maxDataPoints).fill(''),
                datasets: [{
                    label: 'CPU Usage (%)',
                    data: Array(maxDataPoints).fill(0),
                    borderColor: '#4CAF50',
                    backgroundColor: 'rgba(76, 175, 80, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            callback: (value) => `${value}%`
                        }
                    }
                },
                animation: {
                    duration: 500
                }
            }
        });
    }

    if (memoryCtx && !memoryChart) {
        memoryChart = new Chart(memoryCtx, {
            type: 'line',
            data: {
                labels: Array(maxDataPoints).fill(''),
                datasets: [{
                    label: 'Memory Usage (%)',
                    data: Array(maxDataPoints).fill(0),
                    borderColor: '#2196F3',
                    backgroundColor: 'rgba(33, 150, 243, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            callback: (value) => `${value}%`
                        }
                    }
                },
                animation: {
                    duration: 500
                }
            }
        });
    }

    if (diskCtx && !diskChart) {
        diskChart = new Chart(diskCtx, {
            type: 'doughnut',
            data: {
                labels: ['Used', 'Free'],
                datasets: [{
                    data: [0, 100],
                    backgroundColor: ['#FF9800', '#E0E0E0'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                },
                animation: {
                    duration: 500
                }
            }
        });
    }
}

// Update the detailed system stats
function updateDetailedSystemStats() {
    fetch('/api/system/stats')
        .then(response => response.json())
        .then(data => {
            // Update CPU tab
            document.getElementById('cpu-percent').textContent = `${data.cpu.percent}%`;
            document.getElementById('cpu-cores').textContent = data.cpu.cores;
            document.getElementById('cpu-freq').textContent = data.cpu.frequency ? `${Math.round(data.cpu.frequency)} MHz` : 'N/A';

            // Update per-core display
            updateCoreUsage(data.cpu.per_core);

            // Update memory tab
            document.getElementById('memory-percent').textContent = `${data.memory.percent}%`;
            document.getElementById('memory-total').textContent = formatBytes(data.memory.total);
            document.getElementById('memory-available').textContent = formatBytes(data.memory.available);
            document.getElementById('memory-used').textContent = formatBytes(data.memory.used);

            // Update disk tab
            document.getElementById('disk-percent').textContent = `${data.disk.percent}%`;
            document.getElementById('disk-total').textContent = formatBytes(data.disk.total);
            document.getElementById('disk-used').textContent = formatBytes(data.disk.used);
            document.getElementById('disk-free').textContent = formatBytes(data.disk.free);

            // Update charts
            updateSystemCharts(data);
        })
        .catch(error => console.error('Error fetching detailed system stats:', error));
}

// Update the core usage display
function updateCoreUsage(coreData) {
    const coreGrid = document.getElementById('core-usage-grid');
    if (!coreGrid) return;

    // Clear existing cores
    coreGrid.innerHTML = '';

    // Add each core
    coreData.forEach((usage, index) => {
        const coreItem = document.createElement('div');
        coreItem.className = 'core-item';

        const coreName = document.createElement('div');
        coreName.className = 'core-name';
        coreName.textContent = `Core ${index + 1}`;

        const corePercent = document.createElement('div');
        corePercent.className = 'core-percent';
        corePercent.textContent = `${usage}%`;

        coreItem.appendChild(coreName);
        coreItem.appendChild(corePercent);
        coreGrid.appendChild(coreItem);
    });
}

// Update the system monitoring charts
function updateSystemCharts(data) {
    const timestamp = new Date().toLocaleTimeString();

    // Update CPU chart
    if (cpuChart) {
        cpuChart.data.labels.shift();
        cpuChart.data.labels.push(timestamp);
        cpuChart.data.datasets[0].data.shift();
        cpuChart.data.datasets[0].data.push(data.cpu.percent);
        cpuChart.update();
    }

    // Update Memory chart
    if (memoryChart) {
        memoryChart.data.labels.shift();
        memoryChart.data.labels.push(timestamp);
        memoryChart.data.datasets[0].data.shift();
        memoryChart.data.datasets[0].data.push(data.memory.percent);
        memoryChart.update();
    }

    // Update Disk chart
    if (diskChart) {
        diskChart.data.datasets[0].data = [data.disk.percent, 100 - data.disk.percent];
        diskChart.update();
    }
}

// Format bytes to human-readable format
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Configuration Management
function initConfigurationManager() {
    // Initialize the configuration manager functionality
    const configForm = document.getElementById('configuration-form');
    const saveConfigBtn = document.getElementById('save-config');
    const addModelBtn = document.getElementById('add-model-btn');

    if (configForm) {
        // Load configuration when form is shown
        const configModal = document.getElementById('config-modal');
        configModal.addEventListener('show.bs.modal', function () {
            loadConfiguration();
        });

        // Add event listeners
        if (saveConfigBtn) {
            saveConfigBtn.addEventListener('click', saveConfiguration);
        }

        if (addModelBtn) {
            addModelBtn.addEventListener('click', addNewModel);
        }

        // Setup tab switching
        const configTabs = document.querySelectorAll('.config-tab');
        configTabs.forEach(tab => {
            tab.addEventListener('click', function () {
                const tabId = this.getAttribute('data-tab');
                switchConfigTab(tabId);
            });
        });
    }
}

// Load configuration from the server
function loadConfiguration() {
    showToast('Loading configuration...', 'info');

    fetch('/api/config')
        .then(response => {
            if (!response.ok) {
                throw new Error('Failed to load configuration');
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                populateConfigurationForm(data.config);
                showToast('Configuration loaded successfully', 'success');
            } else {
                showToast('Error: ' + (data.error || 'Unknown error'), 'error');
            }
        })
        .catch(error => {
            console.error('Error loading configuration:', error);
            showToast('Failed to load configuration: ' + error.message, 'error');
        });
}

// Populate the configuration form with loaded data
function populateConfigurationForm(config) {
    // Clear existing content
    const llmSection = document.getElementById('llm-config');
    const systemSection = document.getElementById('system-config');
    const uiSection = document.getElementById('ui-config');

    if (llmSection) llmSection.innerHTML = '';
    if (systemSection) systemSection.innerHTML = '';
    if (uiSection) uiSection.innerHTML = '';

    // Populate LLM section
    if (llmSection && config.llm) {
        // Handle global LLM settings
        let globalHtml = `
            <div class="config-group">
                <h4>Global LLM Settings</h4>
                <div class="mb-3">
                    <label for="llm-default-model" class="form-label">Default Model</label>
                    <input type="text" class="form-control" id="llm-default-model" name="llm.model"
                        value="${config.llm.model || ''}">
                </div>
                <div class="mb-3">
                    <label for="llm-temperature" class="form-label">Temperature</label>
                    <input type="number" class="form-control" id="llm-temperature" name="llm.temperature"
                        min="0" max="2" step="0.1" value="${config.llm.temperature || 0.7}">
                </div>
                <div class="mb-3">
                    <label for="llm-api-key" class="form-label">API Key</label>
                    <input type="password" class="form-control" id="llm-api-key" name="llm.api_key"
                        value="${config.llm.api_key || ''}">
                </div>
            </div>
        `;

        llmSection.innerHTML = globalHtml;

        // Add models
        const modelKeys = Object.keys(config.llm).filter(key =>
            typeof config.llm[key] === 'object' && config.llm[key] !== null);

        if (modelKeys.length > 0) {
            let modelsHtml = '<div class="models-container"><h4>Custom Models</h4>';

            modelKeys.forEach(modelKey => {
                const model = config.llm[modelKey];
                if (model && typeof model === 'object') {
                    modelsHtml += createModelCard(modelKey, model);
                }
            });

            modelsHtml += '</div>';
            llmSection.innerHTML += modelsHtml;
        }
    }

    // Populate System section
    if (systemSection && config.system) {
        let systemHtml = `
            <div class="config-group">
                <h4>System Settings</h4>
                <div class="mb-3">
                    <label for="system-max-tokens" class="form-label">Max Tokens Limit</label>
                    <input type="number" class="form-control" id="system-max-tokens" name="system.max_tokens_limit"
                        value="${config.system.max_tokens_limit || 8192}">
                </div>
                <div class="mb-3">
                    <label for="system-concurrent" class="form-label">Max Concurrent Requests</label>
                    <input type="number" class="form-control" id="system-concurrent" name="system.max_concurrent_requests"
                        min="1" max="10" value="${config.system.max_concurrent_requests || 2}">
                </div>
                <div class="form-check mb-3">
                    <input type="checkbox" class="form-check-input" id="system-lightweight" name="system.lightweight_mode"
                        ${config.system.lightweight_mode ? 'checked' : ''}>
                    <label class="form-check-label" for="system-lightweight">Lightweight Mode (disable AI)</label>
                </div>
            </div>
        `;

        systemSection.innerHTML = systemHtml;
    }

    // Populate UI section
    if (uiSection && config.web) {
        let uiHtml = `
            <div class="config-group">
                <h4>UI Settings</h4>
                <div class="mb-3">
                    <label for="web-port" class="form-label">Web Port</label>
                    <input type="number" class="form-control" id="web-port" name="web.port"
                        min="1024" max="65535" value="${config.web.port || 5000}">
                </div>
                <div class="mb-3">
                    <label for="web-theme" class="form-label">Default Theme</label>
                    <select class="form-control" id="web-theme" name="web.theme">
                        <option value="dark" ${(config.web.theme === 'dark') ? 'selected' : ''}>Dark</option>
                        <option value="light" ${(config.web.theme === 'light') ? 'selected' : ''}>Light</option>
                    </select>
                </div>
                <div class="form-check mb-3">
                    <input type="checkbox" class="form-check-input" id="web-debug" name="web.debug"
                        ${config.web.debug ? 'checked' : ''}>
                    <label class="form-check-label" for="web-debug">Debug Mode</label>
                </div>
                <div class="form-check mb-3">
                    <input type="checkbox" class="form-check-input" id="web-save-conversations" name="web.save_conversations"
                        ${config.web.save_conversations ? 'checked' : ''}>
                    <label class="form-check-label" for="web-save-conversations">Save Conversations</label>
                </div>
                <div class="mb-3">
                    <label for="web-max-history" class="form-label">Max History Items</label>
                    <input type="number" class="form-control" id="web-max-history" name="web.max_history"
                        min="10" max="1000" value="${config.web.max_history || 100}">
                </div>
            </div>
        `;

        uiSection.innerHTML = uiHtml;
    }
}

// Create HTML for a model card
function createModelCard(modelId, settings) {
    return `
        <div class="card mb-3 model-card" data-model-id="${modelId}">
            <div class="card-header d-flex justify-content-between">
                <span>${settings.model || modelId}</span>
                <button type="button" class="btn-close" aria-label="Remove"
                    onclick="removeModel('${modelId}')"></button>
            </div>
            <div class="card-body">
                <div class="mb-2">
                    <label class="form-label">Model Name</label>
                    <input type="text" class="form-control" name="llm.${modelId}.model" value="${settings.model || ''}">
                </div>
                <div class="mb-2">
                    <label class="form-label">Base URL</label>
                    <input type="text" class="form-control" name="llm.${modelId}.base_url" value="${settings.base_url || ''}">
                </div>
                <div class="mb-2">
                    <label class="form-label">API Type</label>
                    <select class="form-control" name="llm.${modelId}.api_type">
                        <option value="openai" ${settings.api_type === 'openai' ? 'selected' : ''}>OpenAI</option>
                        <option value="azure" ${settings.api_type === 'azure' ? 'selected' : ''}>Azure</option>
                        <option value="anthropic" ${settings.api_type === 'anthropic' ? 'selected' : ''}>Anthropic</option>
                        <option value="mistral" ${settings.api_type === 'mistral' ? 'selected' : ''}>Mistral</option>
                        <option value="cohere" ${settings.api_type === 'cohere' ? 'selected' : ''}>Cohere</option>
                        <option value="ollama" ${settings.api_type === 'ollama' ? 'selected' : ''}>Ollama</option>
                    </select>
                </div>
                <div class="mb-2">
                    <label class="form-label">API Key</label>
                    <input type="password" class="form-control" name="llm.${modelId}.api_key" value="${settings.api_key || ''}">
                </div>
                <div class="mb-2">
                    <label class="form-label">Temperature</label>
                    <input type="number" class="form-control" name="llm.${modelId}.temperature"
                        min="0" max="2" step="0.1" value="${settings.temperature || 0.7}">
                </div>
            </div>
        </div>
    `;
}

// Add a new model
function addNewModel() {
    const modelId = 'custom_model_' + Date.now();
    const modelSettings = {
        model: 'New Custom Model',
        base_url: '',
        api_key: '',
        api_type: 'openai',
        temperature: 0.7
    };

    // Find the models container
    const modelsContainer = document.querySelector('.models-container');

    // If container doesn't exist, create it
    if (!modelsContainer) {
        const llmSection = document.getElementById('llm-config');
        if (llmSection) {
            const newModelsContainer = document.createElement('div');
            newModelsContainer.className = 'models-container';
            newModelsContainer.innerHTML = '<h4>Custom Models</h4>';
            llmSection.appendChild(newModelsContainer);

            // Add the model card to the new container
            newModelsContainer.insertAdjacentHTML('beforeend', createModelCard(modelId, modelSettings));
        }
    } else {
        // Add the model card to the existing container
        modelsContainer.insertAdjacentHTML('beforeend', createModelCard(modelId, modelSettings));
    }
}

// Remove a model
function removeModel(modelId) {
    const modelCard = document.querySelector(`.model-card[data-model-id="${modelId}"]`);
    if (modelCard) {
        modelCard.remove();
    }
}

// Switch between configuration tabs
function switchConfigTab(tabId) {
    // Hide all tab contents
    const tabContents = document.querySelectorAll('.config-tab-content');
    tabContents.forEach(tab => tab.style.display = 'none');

    // Show the selected tab content
    const selectedTab = document.getElementById(tabId);
    if (selectedTab) {
        selectedTab.style.display = 'block';
    }

    // Update active tab state
    const tabs = document.querySelectorAll('.config-tab');
    tabs.forEach(tab => tab.classList.remove('active'));

    const activeTab = document.querySelector(`.config-tab[data-tab="${tabId}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
    }
}

// Save configuration
function saveConfiguration() {
    const configForm = document.getElementById('configuration-form');
    if (!configForm) return;

    // Show saving message
    showToast('Saving configuration...', 'info');

    // Collect form data
    const formElements = configForm.querySelectorAll('input, select');
    const config = {};

    formElements.forEach(element => {
        // Skip elements without name attribute
        if (!element.name) return;

        // Process path and value
        const path = element.name.split('.');
        let value;

        // Handle different element types
        if (element.type === 'checkbox') {
            value = element.checked;
        } else if (element.type === 'number') {
            value = parseFloat(element.value);
        } else {
            value = element.value;
        }

        // Build nested structure
        let current = config;
        for (let i = 0; i < path.length; i++) {
            const key = path[i];

            if (i === path.length - 1) {
                // Last element, set the value
                current[key] = value;
            } else {
                // Create nested object if needed
                if (!current[key] || typeof current[key] !== 'object') {
                    current[key] = {};
                }
                current = current[key];
            }
        }
    });

    // Send to server
    fetch('/api/config', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ config }),
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Failed to save configuration');
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                showToast('Configuration saved successfully', 'success');

                // Close modal after saving
                const configModal = document.getElementById('config-modal');
                bootstrap.Modal.getInstance(configModal).hide();
            } else {
                showToast('Error: ' + (data.error || 'Unknown error'), 'error');
            }
        })
        .catch(error => {
            console.error('Error saving configuration:', error);
            showToast('Failed to save configuration: ' + error.message, 'error');
        });
}

// Initialize all new features
document.addEventListener('DOMContentLoaded', function () {
    // Initialize the original UI
    initializeUI();

    // Set up event listeners
    setupEventListeners();

    // Initialize system monitoring
    initSystemMonitor();

    // Initialize configuration manager
    initConfigurationManager();

    // Auto-resize textarea
    const userInput = document.getElementById('user-input');
    if (userInput) {
        userInput.addEventListener('input', autoResizeTextarea);
    }

    // Set up modal handling
    document.querySelectorAll('[data-modal]').forEach(button => {
        button.addEventListener('click', function () {
            const modalId = this.dataset.modal;
            document.getElementById(modalId).classList.add('active');
        });
    });

    document.querySelectorAll('.close-modal').forEach(button => {
        button.addEventListener('click', function () {
            this.closest('.modal').classList.remove('active');
        });
    });
});
