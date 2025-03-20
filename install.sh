#!/bin/bash

# OpenManus Easy Installation Script
echo "Starting OpenManus installation..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install git and try again."
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed. Please install Python 3.9+ and try again."
    exit 1
fi

# Clone the repository
echo "Cloning OpenManus repository..."
git clone https://github.com/mannaandpoem/OpenManus.git
cd OpenManus

# Set up virtual environment
echo "Setting up Python virtual environment..."
if command -v python3 -m venv &> /dev/null; then
    python3 -m venv .venv

    # Activate virtual environment
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi

    # Install dependencies
    echo "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create config directory and copy example config
    echo "Setting up configuration..."
    if [ ! -d "config" ]; then
        mkdir -p config
    fi

    if [ ! -f "config/config.toml" ] && [ -f "config/config.example.toml" ]; then
        cp config/config.example.toml config/config.toml
        echo "Created config.toml from example. Please edit config/config.toml to add your API keys."
    fi

    # Installation complete
    echo "OpenManus installation complete!"
    echo "To start using OpenManus:"
    echo "1. Edit config/config.toml to add your API keys"
    echo "2. Run 'python main.py' to start OpenManus"
    echo "3. For the web dashboard, run 'python run_web_app.py'"

else
    echo "Failed to create virtual environment. Please ensure Python venv module is installed."
    echo "You can manually install with: python3 -m pip install -r requirements.txt"
    exit 1
fi
