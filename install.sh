#!/bin/bash

# OpenManus GUI Plus Installer
# Robust installation script with memory management

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

# Check disk space
check_disk_space() {
    # Get available disk space in KB
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        AVAILABLE_SPACE=$(df -k . | tail -1 | awk '{print $4}')
    else
        # Linux and others
        AVAILABLE_SPACE=$(df -k . | tail -1 | awk '{print $4}')
    fi

    # Convert to MB
    AVAILABLE_SPACE_MB=$((AVAILABLE_SPACE / 1024))

    echo -e "${BLUE}Available disk space: ${AVAILABLE_SPACE_MB} MB${NC}"

    # Check if we have at least 1.5GB free for full install
    if [ "$AVAILABLE_SPACE_MB" -lt 1500 ]; then
        echo -e "${YELLOW}Warning: Low disk space detected (${AVAILABLE_SPACE_MB} MB available)${NC}"
        echo -e "${YELLOW}Recommending lightweight installation mode${NC}"
        return 1
    fi
    return 0
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

# Parse arguments
INSTALL_DIR="$PWD/openmanusguiplus"
LIGHTWEIGHT=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--lightweight) LIGHTWEIGHT=true ;;
        -d|--dir) INSTALL_DIR="$2"; shift ;;
        *) INSTALL_DIR="$1" ;;
    esac
    shift
done

echo -e "Installing to: ${GREEN}$INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory"

# Check disk space
if ! check_disk_space; then
    echo -e "${YELLOW}Auto-selecting lightweight mode due to disk space constraints${NC}"
    LIGHTWEIGHT=true
fi

if [ "$LIGHTWEIGHT" = true ]; then
    echo -e "${BLUE}Installing in lightweight mode (minimal dependencies)${NC}"
else
    echo -e "${BLUE}Installing in standard mode (full dependencies)${NC}"
fi

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

# Configure pip to use less memory and disk space
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1

# Upgrade pip with minimal output
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --no-cache-dir --quiet --upgrade pip || echo -e "${YELLOW}Warning: Failed to upgrade pip, continuing anyway...${NC}"

# Install critical dependencies
echo -e "${YELLOW}Installing critical dependencies...${NC}"
pip install --no-cache-dir --quiet wheel setuptools || echo -e "${YELLOW}Warning: Failed to install wheel/setuptools, continuing anyway...${NC}"

# Install core dependencies based on installation mode
echo -e "${YELLOW}Installing core dependencies...${NC}"
if [ "$LIGHTWEIGHT" = true ]; then
    # Lightweight installation - just the basics
    pip install --no-cache-dir --quiet flask flask-socketio flask-cors psutil tomli tomli_w ||
        handle_error "Failed to install core dependencies"

    # Create a requirements-light.txt file for future updates
    cat > requirements-light.txt << EOL
flask==2.3.3
flask-socketio==5.3.6
flask-cors==4.0.0
psutil==5.9.5
tomli==2.0.1
tomli_w==1.0.0
werkzeug==2.3.7
EOL

    echo -e "${GREEN}Installed lightweight dependencies!${NC}"
else
    # Standard installation with LLM dependencies
    pip install --no-cache-dir --quiet flask flask-socketio flask-cors psutil tomli tomli_w tiktoken openai ||
        handle_error "Failed to install core dependencies"

    echo -e "${YELLOW}Installing AI dependencies...${NC}"
    # Try to install the AI-related dependencies, but don't fail if they can't be installed
    pip install --no-cache-dir --quiet tiktoken openai ||
        echo -e "${YELLOW}Warning: Could not install some AI dependencies. Basic functionality will still work.${NC}"

    echo -e "${YELLOW}Installing remaining dependencies...${NC}"
    if [ -f requirements.txt ]; then
        pip install --no-cache-dir --quiet -r requirements.txt ||
            echo -e "${YELLOW}Warning: Some dependencies failed to install. Basic functionality should still work.${NC}"
    fi
fi

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
lightweight_mode = $([ "$LIGHTWEIGHT" = true ] && echo "true" || echo "false")
EOL
fi

# Create a startup script with optimizations
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

# Run with memory optimization
python -X no_debug_ranges run_web_app.py
EOL

chmod +x start.sh

# Create a dependencies management script
echo -e "${YELLOW}Creating dependency management script...${NC}"
cat > manage_deps.sh << EOL
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Activate virtual environment
source "$ACTIVATE_SCRIPT"

# Show usage
if [ "\$#" -eq 0 ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}./manage_deps.sh install-ai${NC} - Install AI dependencies (tiktoken, openai)"
    echo -e "  ${GREEN}./manage_deps.sh install-full${NC} - Install all dependencies"
    echo -e "  ${GREEN}./manage_deps.sh clean-cache${NC} - Clean pip cache to free disk space"
    echo -e "  ${GREEN}./manage_deps.sh check${NC} - Check installed dependencies"
    exit 0
fi

# Set pip options to save space
export PIP_NO_CACHE_DIR=1

case "\$1" in
    install-ai)
        echo -e "${YELLOW}Installing AI dependencies...${NC}"
        pip install --no-cache-dir tiktoken openai
        ;;
    install-full)
        echo -e "${YELLOW}Installing all dependencies...${NC}"
        pip install --no-cache-dir -r requirements.txt
        ;;
    clean-cache)
        echo -e "${YELLOW}Cleaning pip cache...${NC}"
        pip cache purge
        ;;
    check)
        echo -e "${YELLOW}Checking dependencies...${NC}"
        pip list
        ;;
    *)
        echo -e "${RED}Unknown command: \$1${NC}"
        echo -e "${YELLOW}Try ./manage_deps.sh without arguments for usage help${NC}"
        ;;
esac
EOL

chmod +x manage_deps.sh

# Print success message
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}     Installation Completed Successfully!     ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "To run OpenManus GUI Plus:"
echo -e "  1. Navigate to: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "  2. Run the optimized startup script: ${YELLOW}./start.sh${NC}"
echo -e ""
if [ "$LIGHTWEIGHT" = true ]; then
    echo -e "${YELLOW}Note: You installed in lightweight mode without AI dependencies.${NC}"
    echo -e "To add AI capabilities later: ${YELLOW}./manage_deps.sh install-ai${NC}"
fi
echo -e "${GREEN}==============================================${NC}"
