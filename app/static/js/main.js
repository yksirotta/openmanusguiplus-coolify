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
