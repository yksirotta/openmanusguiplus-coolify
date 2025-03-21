#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Activate virtual environment
ACTIVATE_SCRIPT=".venv/bin/activate"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT=".venv/Scripts/activate"
fi
source "$ACTIVATE_SCRIPT"

# Set pip to minimize space
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1

# Get available space in MB
get_space() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        df -m . | tail -1 | awk '{print $4}'
    else
        df -m . | tail -1 | awk '{print $4}'
    fi
}

# Clean all caches and temporary files
clean_all() {
    echo -e "${YELLOW}Cleaning all temporary files...${NC}"

    # Clean Python bytecode files
    echo -e "${YELLOW}Cleaning Python bytecode files...${NC}"
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    find . -name "*.pyd" -delete 2>/dev/null || true

    # Clean temporary files
    echo -e "${YELLOW}Cleaning temporary files...${NC}"
    rm -rf tmp/ 2>/dev/null || true
    rm -rf .pytest_cache/ 2>/dev/null || true
    rm -rf .mypy_cache/ 2>/dev/null || true

    # Clean any pip temp folders that might exist
    rm -rf "$HOME/.cache/pip" 2>/dev/null || true

    # Clean temporary directories in current folder
    find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    # Clean downloads directory
    rm -rf downloads/* 2>/dev/null || true
    rm -rf .downloads/ 2>/dev/null || true

    echo -e "${GREEN}Cleanup complete!${NC}"
}

# Install or update AI dependencies
install_ai() {
    local space=$(get_space)

    echo -e "${YELLOW}Checking if we can install AI dependencies (need ~500MB)...${NC}"

    if [ "$space" -lt 500 ]; then
        echo -e "${RED}Not enough space for AI dependencies.${NC}"
        echo -e "${RED}Available: ${space}MB, Needed: 500MB${NC}"
        return 1
    fi

    echo -e "${GREEN}Installing AI dependencies...${NC}"

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
    local space=$(get_space)
    echo -e "${BLUE}System Information:${NC}"
    echo -e "  Available disk space: ${space}MB"

    echo -e "${BLUE}Installed Packages:${NC}"
    pip list

    echo -e "${BLUE}Python version:${NC}"
    python --version

    echo -e "${BLUE}Environment Settings:${NC}"
    echo -e "  PIP_NO_CACHE_DIR=$PIP_NO_CACHE_DIR"
    echo -e "  PIP_NO_COMPILE=$PIP_NO_COMPILE"
}

# Display help
show_help() {
    echo -e "${BLUE}OpenManus Cache Manager${NC}"
    echo -e "Usage: ./cache-manager.sh [command]"
    echo -e ""
    echo -e "Commands:"
    echo -e "  clean       Clean all temporary files"
    echo -e "  ai          Install AI dependencies (if space available)"
    echo -e "  info        Show system information and installed packages"
    echo -e "  help        Show this help message"
}

# Process command
if [ "$#" -eq 0 ]; then
    show_help
else
    case "$1" in
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
            echo -e "${RED}Unknown command: $1${NC}"
            show_help
            ;;
    esac
fi
