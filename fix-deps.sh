#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
ACTIVATE_SCRIPT=".venv/bin/activate"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT=".venv/Scripts/activate"
fi
source "$ACTIVATE_SCRIPT" || { echo -e "${RED}Failed to activate virtual environment${NC}"; exit 1; }

# Set pip settings
export PIP_NO_CACHE_DIR=1
export PIP_NO_COMPILE=1
export PYTHONUNBUFFERED=1

echo -e "${YELLOW}Installing missing dependencies...${NC}"

# Install loguru for logging
echo -e "${BLUE}Installing loguru...${NC}"
pip install --no-cache-dir loguru==0.7.2 || { echo -e "${RED}Failed to install loguru${NC}"; exit 1; }

# Fix Flask and related dependencies
echo -e "${BLUE}Ensuring Flask dependencies are installed...${NC}"
pip install --no-cache-dir Flask==2.3.3 markupsafe==2.1.3 Werkzeug==2.3.7 Jinja2==3.1.2 click==8.1.7 itsdangerous==2.1.2 || { echo -e "${RED}Failed to install Flask dependencies${NC}"; exit 1; }

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
python -c "from loguru import logger; print('Loguru successfully installed!')" || { echo -e "${RED}Loguru verification failed${NC}"; exit 1; }
python -c "import flask; print(f'Flask version: {flask.__version__}')" || { echo -e "${RED}Flask verification failed${NC}"; exit 1; }

echo -e "${GREEN}All dependencies successfully installed!${NC}"
echo -e "${GREEN}You should now be able to run the application with: python run_web_app.py${NC}"
