#!/bin/bash

# OpenManus GUI Plus Installer
# This script automates the installation of OpenManus GUI Plus

set -e  # Exit on error

echo "=== OpenManus GUI Plus Installer ==="
echo "This script will install the OpenManus GUI Plus dashboard."

# Create a temporary directory
TMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TMP_DIR"

# Function to clean up on exit
cleanup() {
  if [ -d "$TMP_DIR" ]; then
    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

# Determine installation directory
INSTALL_DIR="$HOME/openmanusguiplus"
echo -n "Enter installation directory [$INSTALL_DIR]: "
read custom_dir
if [ -n "$custom_dir" ]; then
  INSTALL_DIR="$custom_dir"
fi

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"
echo "Installing to: $INSTALL_DIR"

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Please install git and try again."
  exit 1
fi

# Clone the repository
echo "Cloning OpenManus GUI Plus repository..."
git clone https://github.com/mhm22332/openmanusguiplus.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
  echo "Python is not installed. Please install Python 3.8+ and try again."
  exit 1
fi

# Determine Python command
PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
  PYTHON_CMD="python"
fi

# Create virtual environment
echo "Creating Python virtual environment..."
$PYTHON_CMD -m venv .venv

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .venv/Scripts/activate
else
  source .venv/bin/activate
fi

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt || {
  echo "Installing core dependencies only..."
  pip install flask flask-socketio flask-cors psutil tomli tomli_w
}

# Create config directory if it doesn't exist
mkdir -p config

# Create basic config if it doesn't exist
if [ ! -f config/config.toml ]; then
  echo "Creating default configuration..."
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
EOL
  echo "Please edit config/config.toml to add your API keys."
fi

# Print success message
echo ""
echo "=== Installation Complete! ==="
echo "To run OpenManus GUI Plus:"
echo "  1. Navigate to: $INSTALL_DIR"
echo "  2. Activate the virtual environment:"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  echo "     .venv\\Scripts\\activate"
else
  echo "     source .venv/bin/activate"
fi
echo "  3. Run the web dashboard: python run_web_app.py"
echo "  4. Access the dashboard at: http://localhost:5000"
echo ""
echo "Enjoy your OpenManus GUI Plus experience!"
