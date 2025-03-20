#!/bin/bash

# OpenManus Efficient Installation Script
echo "Starting OpenManus installation..."

# Function to clean pip cache
clean_pip_cache() {
    echo "Cleaning pip cache to free disk space..."
    pip cache purge
}

# Parse command line arguments
MINIMAL=false
CLEAN_CACHE=true
SKIP_TORCH=false
CUSTOM_ENV=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            MINIMAL=true
            shift
            ;;
        --no-clean-cache)
            CLEAN_CACHE=false
            shift
            ;;
        --skip-torch)
            SKIP_TORCH=true
            shift
            ;;
        --env=*)
            CUSTOM_ENV="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Available options: --minimal, --no-clean-cache, --skip-torch, --env=<path>"
            exit 1
            ;;
    esac
done

# Check requirements
command -v git >/dev/null 2>&1 || { echo "Git is required but not installed. Please install git and try again."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required but not installed. Please install Python 3.9+ and try again."; exit 1; }

# Clean pip cache before starting if enabled
if [ "$CLEAN_CACHE" = true ]; then
    clean_pip_cache
fi

# Check available disk space
if command -v df >/dev/null 2>&1; then
    AVAIL_SPACE=$(df -BM --output=avail . | tail -n 1 | tr -d 'M' | tr -d ' ')
    if [ "$AVAIL_SPACE" -lt 1500 ] && [ "$MINIMAL" = false ] && [ "$SKIP_TORCH" = false ]; then
        echo "Warning: Low disk space detected ($AVAIL_SPACE MB available)"
        echo "Consider using --minimal or --skip-torch flags for a smaller installation"
        read -p "Continue with full installation anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation aborted. Try again with --minimal or --skip-torch flags."
            exit 1
        fi
    fi
fi

# Clone with minimal depth to save space
echo "Cloning OpenManus repository (minimal depth)..."
git clone --depth 1 https://github.com/mhm22332/openmanusguiplus.git
cd openmanusguiplus

# Set up virtual environment with custom path if provided
ENV_PATH=".venv"
if [ -n "$CUSTOM_ENV" ]; then
    ENV_PATH="$CUSTOM_ENV"
fi

echo "Setting up Python virtual environment at $ENV_PATH..."
python3 -m venv "$ENV_PATH" || { echo "Failed to create virtual environment. Please install venv with 'pip install virtualenv'"; exit 1; }

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source "$ENV_PATH/Scripts/activate"
else
    source "$ENV_PATH/bin/activate"
fi

# Prepare for installation
echo "Upgrading pip..."
pip install --upgrade pip

# Clean cache after pip upgrade if enabled
if [ "$CLEAN_CACHE" = true ]; then
    clean_pip_cache
fi

# Create temporary requirements file based on installation type
if [ "$MINIMAL" = true ]; then
    echo "Preparing minimal installation..."
    grep -v "torch\|tensorflow" requirements.txt > minimal_requirements.txt
    pip install -r minimal_requirements.txt
elif [ "$SKIP_TORCH" = true ]; then
    echo "Installing dependencies (skipping PyTorch)..."
    grep -v "torch" requirements.txt > notorch_requirements.txt
    pip install -r notorch_requirements.txt
else
    echo "Installing all dependencies..."
    # Install in batches to better manage memory
    grep "^[^#]" requirements.txt | grep -v "torch\|tensorflow" > base_requirements.txt
    pip install -r base_requirements.txt

    # Clean up between major package installations if enabled
    if [ "$CLEAN_CACHE" = true ]; then
        clean_pip_cache
    fi

    # Install torch separately
    echo "Installing PyTorch (large package)..."
    grep "torch" requirements.txt > torch_requirements.txt
    pip install -r torch_requirements.txt
fi

# Final cache cleanup if enabled
if [ "$CLEAN_CACHE" = true ]; then
    clean_pip_cache
fi

# Remove temporary requirements files
rm -f minimal_requirements.txt notorch_requirements.txt base_requirements.txt torch_requirements.txt 2>/dev/null

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

if [ "$MINIMAL" = true ]; then
    echo ""
    echo "Note: You installed the minimal version without PyTorch or TensorFlow."
    echo "Some advanced features may not be available."
fi

if [ "$SKIP_TORCH" = true ]; then
    echo ""
    echo "Note: PyTorch was not installed. Some features may not be available."
    echo "To install PyTorch later, run: pip install torch"
fi
