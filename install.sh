#!/bin/bash
# OpenManus GUI Plus Installer - Smart Edition
# Optimized for minimal space requirements with direct file management

set -e  # Exit on error

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}       OpenManus GUI Plus Installer          ${NC}"
echo -e "${GREEN}==============================================${NC}"

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Get available disk space in MB
get_available_space() {
    local available
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        available=$(df -m . | tail -1 | awk '{print $4}')
    else
        # Linux and others
        available=$(df -m . | tail -1 | awk '{print $4}')
    fi
    echo "$available"
}

# Installation directory - default to current directory
INSTALL_DIR="$PWD/openmanusguiplus"
if [ -n "$1" ]; then
    INSTALL_DIR="$1"
fi

echo -e "Installing to: ${GREEN}$INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git is not installed.${NC}"
    echo -e "Please install git using your package manager and try again."
    exit 1
fi

# Check for Python
PY_CMD=""
if command -v python3 &> /dev/null; then
    PY_CMD="python3"
elif command -v python &> /dev/null; then
    PY_CMD="python"
else
    handle_error "Python is not installed. Please install Python 3.8+ and try again."
fi

echo -e "Using Python command: ${GREEN}$PY_CMD${NC}"

# Check disk space
AVAILABLE_SPACE=$(get_available_space)
echo -e "${BLUE}Available disk space: ${AVAILABLE_SPACE}MB${NC}"

if [ "$AVAILABLE_SPACE" -lt 100 ]; then
    echo -e "${YELLOW}Warning: Very low disk space detected (${AVAILABLE_SPACE}MB available)${NC}"
    echo -e "${YELLOW}Installation may fail. Consider freeing up at least 100MB.${NC}"
fi

# Clone the repository (shallow clone to save space)
echo -e "${YELLOW}Cloning repository (minimal size)...${NC}"
git clone --depth=1 --no-tags --single-branch --branch main https://github.com/mhm22332/openmanusguiplus.git "$INSTALL_DIR" || handle_error "Failed to clone repository"
cd "$INSTALL_DIR" || handle_error "Failed to enter installation directory"

# Clean git objects to save space
echo -e "${YELLOW}Optimizing repository size...${NC}"
rm -rf .git/objects/pack/* .git/objects/info/* .git/refs/remotes/ .git/logs/ .git/hooks/ || true

# Create virtual environment with specific Python version
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
$PY_CMD -m venv .venv || handle_error "Failed to create virtual environment"

# Activate virtual environment
ACTIVATE_SCRIPT=".venv/bin/activate"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT=".venv/Scripts/activate"
fi

echo -e "${YELLOW}Activating virtual environment...${NC}"
source "$ACTIVATE_SCRIPT" || handle_error "Failed to activate virtual environment"

# Create requirements file with core dependencies
echo -e "${YELLOW}Creating optimized requirements file...${NC}"
cat > requirements.txt << EOL
# Core web server (essential)
flask==2.3.3
werkzeug==2.3.7
markupsafe==2.1.3
jinja2==3.1.2
itsdangerous==2.1.2
click==8.1.7

# Web functionality
flask-socketio==5.3.6
flask-cors==4.0.0

# System monitoring
psutil==5.9.5

# Configuration utilities
tomli==2.0.1
tomli_w==1.0.0

# AI capabilities (optional)
# Comment these out if space is limited
# tiktoken
# openai
EOL

# Set environment variables for pip
echo -e "${YELLOW}Configuring pip for minimal space usage...${NC}"
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1
export PIP_DISABLE_PIP_VERSION_CHECK=1

# Create cache manager script
echo -e "${YELLOW}Creating file manager script...${NC}"
cat > cache-manager.sh << EOL
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Activate virtual environment
ACTIVATE_SCRIPT=".venv/bin/activate"
if [[ "\$OSTYPE" == "msys" || "\$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT=".venv/Scripts/activate"
fi
source "\$ACTIVATE_SCRIPT"

# Set pip to minimize space
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1

# Get available space in MB
get_space() {
    if [[ "\$OSTYPE" == "darwin"* ]]; then
        df -m . | tail -1 | awk '{print \$4}'
    else
        df -m . | tail -1 | awk '{print \$4}'
    fi
}

# Clean all caches and temporary files
clean_all() {
    echo -e "\${YELLOW}Cleaning all temporary files...\${NC}"

    # Clean Python bytecode files
    echo -e "\${YELLOW}Cleaning Python bytecode files...\${NC}"
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    find . -name "*.pyd" -delete 2>/dev/null || true

    # Clean temporary files
    echo -e "\${YELLOW}Cleaning temporary files...\${NC}"
    rm -rf tmp/ 2>/dev/null || true
    rm -rf .pytest_cache/ 2>/dev/null || true
    rm -rf .mypy_cache/ 2>/dev/null || true

    # Clean any pip temp folders that might exist
    rm -rf "\$HOME/.cache/pip" 2>/dev/null || true

    # Clean temporary directories in current folder
    find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    # Clean downloads directory
    rm -rf downloads/* 2>/dev/null || true
    rm -rf .downloads/ 2>/dev/null || true

    echo -e "\${GREEN}Cleanup complete!\${NC}"
}

# Install or update AI dependencies
install_ai() {
    local space=\$(get_space)

    echo -e "\${YELLOW}Checking if we can install AI dependencies (need ~500MB)...\${NC}"

    if [ "\$space" -lt 500 ]; then
        echo -e "\${RED}Not enough space for AI dependencies.\${NC}"
        echo -e "\${RED}Available: \${space}MB, Needed: 500MB\${NC}"
        return 1
    fi

    echo -e "\${GREEN}Installing AI dependencies...\${NC}"

    # Ensure pip settings are properly set
    export PIP_NO_CACHE_DIR=1
    export PIP_NO_COMPILE=1

    # Install directly without using pip cache
    pip install --no-cache-dir openai tiktoken

    # Update config
    sed -i 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml 2>/dev/null || \
    sed -i '' 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml

    return 0
}

# Show system info
show_info() {
    local space=\$(get_space)
    echo -e "\${BLUE}System Information:\${NC}"
    echo -e "  Available disk space: \${space}MB"

    echo -e "\${BLUE}Installed Packages:\${NC}"
    pip list

    echo -e "\${BLUE}Python version:\${NC}"
    python --version

    echo -e "\${BLUE}Environment Settings:\${NC}"
    echo -e "  PIP_NO_CACHE_DIR=\$PIP_NO_CACHE_DIR"
    echo -e "  PIP_NO_COMPILE=\$PIP_NO_COMPILE"
}

# Display help
show_help() {
    echo -e "\${BLUE}OpenManus Cache Manager\${NC}"
    echo -e "Usage: ./cache-manager.sh [command]"
    echo -e ""
    echo -e "Commands:"
    echo -e "  clean       Clean all temporary files"
    echo -e "  ai          Install AI dependencies (if space available)"
    echo -e "  info        Show system information and installed packages"
    echo -e "  help        Show this help message"
}

# Process command
if [ "\$#" -eq 0 ]; then
    show_help
else
    case "\$1" in
        clean)
            clean_all
            ;;
        ai)
            install_ai
            ;;
        info)
            show_info
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "\${RED}Unknown command: \$1\${NC}"
            show_help
            ;;
    esac
fi
EOL

chmod +x cache-manager.sh

# Create config directory
mkdir -p config

# Create smart configuration file
echo -e "${YELLOW}Creating adaptive configuration...${NC}"
cat > config/config.toml << EOL
# Global LLM configuration
[llm]
model = "gpt-4o"
base_url = "https://api.openai.com/v1"
api_key = ""  # Replace with your actual API key
max_tokens = 4096
temperature = 0.7
api_type = "openai"
api_version = ""

# Web UI configuration
[web]
port = 5000
debug = false

# Memory management settings
[system]
max_tokens_limit = 8192
max_concurrent_requests = 2
lightweight_mode = true
cache_dir = ".cache"
EOL

# Create optimized startup script
echo -e "${YELLOW}Creating optimized startup script...${NC}"
cat > start.sh << EOL
#!/bin/bash

# Memory optimization for OpenManus GUI Plus
export MALLOC_TRIM_THRESHOLD_=65536
export PYTHONMALLOC=malloc
export PYTHONTRACEMALLOC=0
export PYTHONIOENCODING=utf-8
export MPLBACKEND=Agg
export PIP_NO_CACHE_DIR=1

# Activate virtual environment
source "$ACTIVATE_SCRIPT"

# Clean temporary files before starting
./cache-manager.sh clean

# Run with memory optimization
python -X no_debug_ranges run_web_app.py
EOL

chmod +x start.sh

# Set temp directory to the installation directory to avoid filling /tmp
export TMPDIR="$INSTALL_DIR/tmp"
mkdir -p "$TMPDIR"

# Clean temporary files
echo -e "${YELLOW}Cleaning temporary files before installation...${NC}"
# Clean Python bytecode files
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "*.pyo" -delete 2>/dev/null || true
find . -name "*.pyd" -delete 2>/dev/null || true

# Install minimal dependencies first
echo -e "${YELLOW}Installing minimal dependencies...${NC}"
pip install --no-cache-dir Flask==2.3.3 markupsafe==2.1.3 Werkzeug==2.3.7 Jinja2==3.1.2 click==8.1.7 itsdangerous==2.1.2 loguru==0.7.2

# Check disk space again
SPACE_AFTER_MINIMAL=$(get_available_space)
echo -e "${BLUE}Available disk space after minimal install: ${SPACE_AFTER_MINIMAL}MB${NC}"

# Install web functionality if space allows
if [ "$SPACE_AFTER_MINIMAL" -gt 50 ]; then
    echo -e "${YELLOW}Installing web functionality...${NC}"
    pip install --no-cache-dir flask-socketio==5.3.6 flask-cors==4.0.0 psutil==5.9.5

    # Check disk space again
    SPACE_AFTER_WEB=$(get_available_space)

    # Install config utilities if space allows
    if [ "$SPACE_AFTER_WEB" -gt 30 ]; then
        echo -e "${YELLOW}Installing configuration utilities...${NC}"
        pip install --no-cache-dir tomli==2.0.1 tomli_w==1.0.0
    fi
else
    echo -e "${YELLOW}Limited disk space: Skipping additional web dependencies${NC}"
fi

# Clean temp directory to save space
rm -rf "$TMPDIR"

# Run our file cleanup script
echo -e "${YELLOW}Running final cleanup...${NC}"
./cache-manager.sh clean

# Print success message
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}     Installation Completed Successfully!     ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "To run OpenManus GUI Plus:"
echo -e "  1. Navigate to: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "  2. Run: ${YELLOW}./start.sh${NC}"
echo -e ""
echo -e "To manage files and dependencies:"
echo -e "  Run: ${YELLOW}./cache-manager.sh help${NC}"
echo -e ""
echo -e "To install AI capabilities if you have enough space (500MB+):"
echo -e "  Run: ${YELLOW}./cache-manager.sh ai${NC}"
echo -e "${GREEN}==============================================${NC}"
