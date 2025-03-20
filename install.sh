#!/bin/bash

# OpenManus GUI Plus Installer
# Robust installation script with memory management

set -e  # Exit on error

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check dependencies
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 is not installed.${NC}"
        echo -e "Please install $1 using: $2"
        return 1
    fi
    return 0
}

# Installation directory - default to current directory
INSTALL_DIR="$PWD/openmanusguiplus"
if [ -n "$1" ]; then
    INSTALL_DIR="$1"
fi

echo -e "Installing to: ${GREEN}$INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory"

# Check for git
check_dependency "git" "apt-get install git" || handle_error "Git is required"

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

# Clone the repository
echo -e "${YELLOW}Cloning repository...${NC}"
git clone https://github.com/mhm22332/openmanusguiplus.git "$INSTALL_DIR" || handle_error "Failed to clone repository"
cd "$INSTALL_DIR" || handle_error "Failed to enter installation directory"

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

# Configure pip to use less memory
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1

# Install dependencies with memory optimization
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --no-cache-dir --upgrade pip || echo -e "${YELLOW}Warning: Failed to upgrade pip, continuing anyway...${NC}"

echo -e "${YELLOW}Installing critical dependencies...${NC}"
pip install --no-cache-dir wheel setuptools || echo -e "${YELLOW}Warning: Failed to install wheel/setuptools, continuing anyway...${NC}"

echo -e "${YELLOW}Installing core dependencies...${NC}"
pip install --no-cache-dir flask flask-socketio flask-cors psutil tomli tomli_w tiktoken openai || handle_error "Failed to install core dependencies"

echo -e "${YELLOW}Installing remaining dependencies...${NC}"
pip install --no-cache-dir -r requirements.txt || echo -e "${YELLOW}Warning: Some dependencies failed to install. Basic functionality should still work.${NC}"

# Create config directory if needed
mkdir -p config

# Create default config if needed
if [ ! -f config/config.toml ]; then
    echo -e "${YELLOW}Creating default configuration...${NC}"
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
# Lower these values on low-memory systems
max_tokens_limit = 8192
max_concurrent_requests = 2
EOL
fi

# Create a startup script that optimizes memory usage
echo -e "${YELLOW}Creating optimized startup script...${NC}"
cat > start.sh << EOL
#!/bin/bash

# Memory optimization for OpenManus GUI Plus
export MALLOC_TRIM_THRESHOLD_=65536
export PYTHONMALLOC=malloc
export PYTHONTRACEMALLOC=0
export PYTHONIOENCODING=utf-8
export MPLBACKEND=Agg

# Activate virtual environment
source "$ACTIVATE_SCRIPT"

# Run with memory optimization
python -X no_debug_ranges run_web_app.py
EOL

chmod +x start.sh

# Print success message
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}     Installation Completed Successfully!     ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "To run OpenManus GUI Plus:"
echo -e "  1. Navigate to: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "  2. Run the optimized startup script: ${YELLOW}./start.sh${NC}"
echo -e "  3. Or activate the environment manually:"
echo -e "     ${YELLOW}source $ACTIVATE_SCRIPT${NC}"
echo -e "     ${YELLOW}python run_web_app.py${NC}"
echo -e "  4. Access the dashboard at: ${GREEN}http://localhost:5000${NC}"
