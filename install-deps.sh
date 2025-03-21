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

# Configure pip
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1

# Get available space in MB
get_space() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        df -m . | tail -1 | awk '{print $4}'
    else
        df -m . | tail -1 | awk '{print $4}'
    fi
}

# Install a tier with space check
install_tier() {
    local tier=$1
    local needed=$2
    local desc=$3
    local use_deps=$4  # Whether to use --no-deps flag (false) or allow dependencies (true)

    echo -e "${YELLOW}Checking if we can install ${desc} (${needed}MB needed)...${NC}"
    local space=$(get_space)

    if [ "$space" -lt "$needed" ]; then
        echo -e "${RED}Not enough space to install ${desc}.${NC}"
        echo -e "${RED}Available: ${space}MB, Needed: ${needed}MB${NC}"
        return 1
    fi

    echo -e "${GREEN}Installing ${desc}...${NC}"

    # Allow dependencies for tier 1 as it has the critical Flask dependencies
    # Use --no-deps for other tiers to save space
    if [ "$use_deps" = "true" ]; then
        pip install --no-cache-dir -r "requirements-tier${tier}.txt" && touch ".tier${tier}-installed"
    else
        pip install --no-cache-dir --no-deps -r "requirements-tier${tier}.txt" && touch ".tier${tier}-installed"
    fi

    local result=$?

    if [ $result -ne 0 ]; then
        echo -e "${RED}Failed to install ${desc}.${NC}"
        # Try again with regular pip install if --no-deps failed
        if [ "$use_deps" = "false" ]; then
            echo -e "${YELLOW}Trying again with dependencies...${NC}"
            pip install --no-cache-dir -r "requirements-tier${tier}.txt" && touch ".tier${tier}-installed"
            result=$?
            if [ $result -ne 0 ]; then
                return $result
            fi
        else
            return $result
        fi
    fi

    echo -e "${GREEN}Successfully installed ${desc}!${NC}"
    return 0
}

# Always try to install lower tiers if not already installed
if [ ! -f ".tier1-installed" ]; then
    # Allow dependencies for tier 1 (critical Flask dependencies)
    install_tier 1 50 "core web server" "true" || exit 1
fi

if [ ! -f ".tier2-installed" ]; then
    install_tier 2 30 "web functionality" "false" || echo -e "${YELLOW}Continuing with limited web functionality${NC}"
fi

if [ ! -f ".tier3-installed" ]; then
    install_tier 3 20 "configuration utilities" "false" || echo -e "${YELLOW}Continuing with limited configuration capabilities${NC}"
fi

if [ ! -f ".tier4-installed" ]; then
    install_tier 4 500 "AI capabilities" "false" || echo -e "${YELLOW}AI capabilities not installed. Run this script later when you have more disk space.${NC}"
fi

# Summarize what's installed
echo -e "${BLUE}Installation summary:${NC}"
[ -f ".tier1-installed" ] && echo -e "  ✅ Core web server" || echo -e "  ❌ Core web server"
[ -f ".tier2-installed" ] && echo -e "  ✅ Web functionality" || echo -e "  ❌ Web functionality"
[ -f ".tier3-installed" ] && echo -e "  ✅ Configuration utilities" || echo -e "  ❌ Configuration utilities"
[ -f ".tier4-installed" ] && echo -e "  ✅ AI capabilities" || echo -e "  ❌ AI capabilities (run this script later to add them)"

# Update config based on what's installed
if [ -f ".tier4-installed" ]; then
    sed -i 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml 2>/dev/null || \
    sed -i '' 's/lightweight_mode = true/lightweight_mode = false/' config/config.toml
fi

echo -e "${GREEN}Done! Run ./start.sh to start the application.${NC}"
