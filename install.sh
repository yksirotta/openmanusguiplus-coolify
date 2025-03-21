#!/bin/bash

# OpenManus GUI Plus Installer
# Smart installation with automatic space optimization

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

# Clone the repository (shallow clone to save space)
echo -e "${YELLOW}Cloning repository (minimal size)...${NC}"
git clone --depth=1 https://github.com/mhm22332/openmanusguiplus.git "$INSTALL_DIR" || handle_error "Failed to clone repository"
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

# Configure pip to minimize disk usage
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1

# Create requirements files by priority
echo -e "${YELLOW}Preparing optimized installation plan...${NC}"

# Create tier 1 - absolute minimum dependencies (very small footprint)
cat > requirements-tier1.txt << EOL
flask==2.3.3
werkzeug==2.3.7
EOL

# Create tier 2 - basic web functionality (small footprint)
cat > requirements-tier2.txt << EOL
flask-socketio==5.3.6
flask-cors==4.0.0
psutil==5.9.5
EOL

# Create tier 3 - configuration and utilities (medium footprint)
cat > requirements-tier3.txt << EOL
tomli==2.0.1
tomli_w==1.0.0
EOL

# Create tier 4 - AI dependencies (large footprint)
cat > requirements-tier4.txt << EOL
tiktoken
openai
EOL

# Create config directory
mkdir -p config

# Create smart configuration file that adapts to installed dependencies
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
# Sets itself automatically based on what's installed
lightweight_mode = true
EOL

# Create smart installer script that can resume installation
echo -e "${YELLOW}Creating smart dependency installer...${NC}"
cat > install-deps.sh << EOL
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

# Configure pip
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1

# Get available space in MB
get_space() {
    if [[ "\$OSTYPE" == "darwin"* ]]; then
        df -m . | tail -1 | awk '{print \$4}'
    else
        df -m . | tail -1 | awk '{print \$4}'
    fi
}

# Install a tier with space check
install_tier() {
    local tier=\$1
    local needed=\$2
    local desc=\$3

    echo -e "\${YELLOW}Checking if we can install \${desc} (\${needed}MB needed)...\${NC}"
    local space=\$(get_space)

    if [ "\$space" -lt "\$needed" ]; then
        echo -e "\${RED}Not enough space to install \${desc}.\${NC}"
        echo -e "\${RED}Available: \${space}MB, Needed: \${needed}MB\${NC}"
        return 1
    fi

    echo -e "\${GREEN}Installing \${desc}...\${NC}"
    pip install --no-cache-dir --no-deps -r "requirements-tier\${tier}.txt" && touch ".tier\${tier}-installed"
    local result=\$?

    if [ \$result -ne 0 ]; then
        echo -e "\${RED}Failed to install \${desc}.\${NC}"
        return \$result
    fi

    echo -e "\${GREEN}Successfully installed \${desc}!\${NC}"
    return 0
}

# Always try to install lower tiers if not already installed
if [ ! -f ".tier1-installed" ]; then
    install_tier 1 20 "core web server" || exit 1
fi

if [ ! -f ".tier2-installed" ]; then
    install_tier 2 30 "web functionality" || echo -e "\${YELLOW}Continuing with limited web functionality\${NC}"
fi

if [ ! -f ".tier3-installed" ]; then
    install_tier 3 20 "configuration utilities" || echo -e "\${YELLOW}Continuing with limited configuration capabilities\${NC}"
fi

if [ ! -f ".tier4-installed" ]; then
    install_tier 4 500 "AI capabilities" || echo -e "\${YELLOW}AI capabilities not installed. Run this script later when you have more disk space.\${NC}"
fi

# Summarize what's installed
echo -e "\${BLUE}Installation summary:\${NC}"
[ -f ".tier1-installed" ] && echo -e "  ✅ Core web server" || echo -e "  ❌ Core web server"
[ -f ".tier2-installed" ] && echo -e "  ✅ Web functionality" || echo -e "  ❌ Web functionality"
[ -f ".tier3-installed" ] && echo -e "  ✅ Configuration utilities" || echo -e "  ❌ Configuration utilities"
[ -f ".tier4-installed" ] && echo -e "  ✅ AI capabilities" || echo -e "  ❌ AI capabilities (run this script later to add them)"

# Update config based on what's installed
if [ -f ".tier4-installed" ]; then
    sed -i 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml 2>/dev/null || \
    sed -i '' 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml
fi

echo -e "\${GREEN}Done! Run ./start.sh to start the application.\${NC}"
EOL

chmod +x install-deps.sh

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

# Check if any dependencies are installed before starting
if [ ! -f ".tier1-installed" ]; then
    echo "First-time setup: Installing critical dependencies..."
    ./install-deps.sh
fi

# Run with memory optimization
python -X no_debug_ranges run_web_app.py
EOL

chmod +x start.sh

# Create disk space cleanup utility
echo -e "${YELLOW}Creating space cleanup utility...${NC}"
cat > cleanup-space.sh << EOL
#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\${YELLOW}Cleaning up to free disk space...\${NC}"

# Activate virtual environment
source "$ACTIVATE_SCRIPT"

# Clean pip cache
pip cache purge

# Remove __pycache__ directories
find . -type d -name "__pycache__" -exec rm -rf {} +

# Clean temporary files
rm -rf /tmp/pip-* 2>/dev/null
rm -rf /tmp/pip_build_* 2>/dev/null
rm -rf .pytest_cache 2>/dev/null

# Remove compiled Python files
find . -name "*.pyc" -delete
find . -name "*.pyo" -delete
find . -name "*.pyd" -delete

# Clean downloads
rm -rf downloads/* 2>/dev/null

echo -e "\${GREEN}Cleanup complete!\${NC}"
EOL

chmod +x cleanup-space.sh

# Now run the dependency installer
echo -e "${YELLOW}Starting smart dependency installation...${NC}"
./install-deps.sh

# Print success message
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}     Installation Completed Successfully!     ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "To run OpenManus GUI Plus:"
echo -e "  1. Navigate to: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "  2. Run: ${YELLOW}./start.sh${NC}"
echo -e ""
echo -e "If you need to add AI capabilities later:"
echo -e "  Run: ${YELLOW}./install-deps.sh${NC}"
echo -e ""
echo -e "To free up disk space:"
echo -e "  Run: ${YELLOW}./cleanup-space.sh${NC}"
echo -e "${GREEN}==============================================${NC}"
