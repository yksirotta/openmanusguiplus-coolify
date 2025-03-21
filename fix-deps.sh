#!/bin/bash

# Direct fix for dependency issues
echo "Force-installing critical Flask dependencies..."

# Activate virtual environment
ACTIVATE_SCRIPT=".venv/bin/activate"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ACTIVATE_SCRIPT=".venv/Scripts/activate"
fi
source "$ACTIVATE_SCRIPT"

# Disable cache to save space
export PIP_NO_CACHE_DIR=1

# Install dependencies directly (no requirements file)
echo "Installing markupsafe..."
pip install markupsafe==2.1.3

echo "Installing other critical Flask dependencies..."
pip install click==8.1.7 itsdangerous==2.1.2 jinja2==3.1.2

echo "Verifying Flask installation..."
pip install --upgrade flask==2.3.3

echo "Testing if markupsafe is properly installed..."
python -c "import markupsafe; print(f\"markupsafe version: {markupsafe.__version__}\")"

echo "Done! Now try running ./start.sh again."
