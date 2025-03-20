#!/bin/bash

# OpenManus Smart Installation Script
echo "🚀 OpenManus Smart Installer"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation stages
STAGE_BASIC=true      # Core files and basic dependencies
STAGE_STANDARD=true   # Non-ML dependencies
STAGE_ML=true         # Machine learning libraries
STAGE_TORCH=true      # PyTorch (largest component)
STAGE_CONFIG=true     # Configure the system

# Installation location
INSTALL_DIR="openmanusguiplus"
ENV_PATH=".venv"
REPO_URL="https://github.com/mhm22332/openmanusguiplus.git"
MIN_SPACE_REQUIRED=250  # MB, minimum for basic installation
TORCH_SPACE_REQUIRED=800 # MB, space needed for PyTorch

# Function to print colored messages
print_message() {
    case $1 in
        "info") printf "${BLUE}[INFO]${NC} $2\n" ;;
        "success") printf "${GREEN}[SUCCESS]${NC} $2\n" ;;
        "warning") printf "${YELLOW}[WARNING]${NC} $2\n" ;;
        "error") printf "${RED}[ERROR]${NC} $2\n" ;;
        *) echo "$2" ;;
    esac
}

# Function to clean pip cache
clean_pip_cache() {
    print_message "info" "Cleaning pip cache to free disk space..."
    pip cache purge 2>/dev/null || pip cache remove "*" 2>/dev/null || true
}

# Function to check available disk space in MB
check_disk_space() {
    if command -v df &>/dev/null; then
        # Try to get available space in MB
        df_output=$(df -m . | tail -n 1)
        available_space=$(echo "$df_output" | awk '{print $4}')

        # If awk or tail failed, try another method
        if [ -z "$available_space" ] || ! [[ "$available_space" =~ ^[0-9]+$ ]]; then
            available_space=$(df -k . | tail -n 1 | awk '{print int($4/1024)}')
        fi

        echo "$available_space"
    else
        # If df is not available, return a large number to bypass the check
        echo "999999"
    fi
}

# Function to ask user yes/no question with default
ask_yes_no() {
    local prompt="$1"
    local default="$2"

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response

    if [ -z "$response" ]; then
        response="$default"
    fi

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "yes"
            ;;
        *)
            echo "no"
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            STAGE_ML=false
            STAGE_TORCH=false
            shift
            ;;
        --skip-torch)
            STAGE_TORCH=false
            shift
            ;;
        --basic-only)
            STAGE_ML=false
            STAGE_TORCH=false
            STAGE_STANDARD=false
            shift
            ;;
        --install-dir=*)
            INSTALL_DIR="${1#*=}"
            shift
            ;;
        --env=*)
            ENV_PATH="${1#*=}"
            shift
            ;;
        --help)
            echo "OpenManus Smart Installer"
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --minimal        Skip ML libraries and PyTorch"
            echo "  --skip-torch     Skip PyTorch installation (saves ~800MB)"
            echo "  --basic-only     Install only the core dependencies"
            echo "  --install-dir=*  Specify installation directory"
            echo "  --env=*          Specify virtual environment path"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            print_message "error" "Unknown option: $1"
            echo "Use --help for available options"
            exit 1
            ;;
    esac
done

# Check for required tools
for cmd in git python3 pip; do
    if ! command -v $cmd &>/dev/null; then
        print_message "error" "$cmd is required but not installed."
        exit 1
    fi
done

# Check disk space before starting
available_space=$(check_disk_space)
print_message "info" "Available disk space: ${available_space}MB"

if [ "$available_space" -lt "$MIN_SPACE_REQUIRED" ]; then
    print_message "error" "Not enough disk space. At least ${MIN_SPACE_REQUIRED}MB is required."
    print_message "info" "Try clearing disk space and run the installer again."
    exit 1
fi

if [ "$STAGE_TORCH" = true ] && [ "$available_space" -lt "$TORCH_SPACE_REQUIRED" ]; then
    print_message "warning" "Low disk space for PyTorch installation (${available_space}MB available, ${TORCH_SPACE_REQUIRED}MB recommended)"
    response=$(ask_yes_no "Do you want to continue with PyTorch installation?" "n")

    if [ "$response" = "no" ]; then
        print_message "info" "Disabling PyTorch installation"
        STAGE_TORCH=false
    fi
fi

# STAGE 1: Download and clone repository
if [ "$STAGE_BASIC" = true ]; then
    print_message "info" "Stage 1: Downloading OpenManus core files..."

    # Clone with minimal depth to save space
    git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        print_message "error" "Failed to clone repository."
        exit 1
    fi

    cd "$INSTALL_DIR"

    # Only checkout what's necessary for basic installation
    git sparse-checkout set app/agent app/prompt app/schema.py app/config.py requirements.txt main.py README.md config LICENSE

    print_message "success" "Core files downloaded successfully"
fi

# STAGE 2: Set up virtual environment
if [ "$STAGE_BASIC" = true ]; then
    print_message "info" "Stage 2: Setting up Python environment..."

    # Set up virtual environment
    python3 -m venv "$ENV_PATH" || { print_message "error" "Failed to create virtual environment."; exit 1; }

    # Activate virtual environment
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source "$ENV_PATH/Scripts/activate"
    else
        source "$ENV_PATH/bin/activate"
    fi

    # Upgrade pip
    pip install --upgrade pip

    print_message "success" "Python environment created successfully"
fi

# STAGE 3: Install basic dependencies
if [ "$STAGE_BASIC" = true ]; then
    print_message "info" "Stage 3: Installing basic dependencies..."

    # Extract basic dependencies
    grep -v "tensorflow\|torch\|numpy\|pandas\|scipy\|matplotlib" requirements.txt > basic_requirements.txt
    pip install -r basic_requirements.txt

    if [ $? -ne 0 ]; then
        print_message "warning" "Some basic dependencies failed to install."
        print_message "info" "Continuing with installation..."
    else
        print_message "success" "Basic dependencies installed successfully"
    fi
    rm basic_requirements.txt
fi

# Clean cache
clean_pip_cache

# STAGE 4: Install standard libraries
if [ "$STAGE_STANDARD" = true ]; then
    # Check disk space again
    available_space=$(check_disk_space)
    if [ "$available_space" -lt 100 ]; then
        print_message "warning" "Low disk space (${available_space}MB). Skipping standard libraries."
        STAGE_STANDARD=false
    else
        print_message "info" "Stage 4: Installing standard libraries..."

        # Extract standard libraries
        grep -e "numpy\|pandas\|matplotlib" requirements.txt > standard_requirements.txt
        pip install -r standard_requirements.txt

        if [ $? -ne 0 ]; then
            print_message "warning" "Some standard libraries failed to install."
        else
            print_message "success" "Standard libraries installed successfully"
        fi
        rm standard_requirements.txt
    fi
fi

# Clean cache
clean_pip_cache

# STAGE 5: Install ML libraries (except PyTorch)
if [ "$STAGE_ML" = true ]; then
    # Check disk space again
    available_space=$(check_disk_space)
    if [ "$available_space" -lt 200 ]; then
        print_message "warning" "Low disk space (${available_space}MB). Skipping ML libraries."
        STAGE_ML=false
    else
        print_message "info" "Stage 5: Installing ML libraries..."

        # Extract ML libraries except PyTorch
        grep -e "tensorflow\|scikit-learn\|scipy" requirements.txt | grep -v "torch" > ml_requirements.txt

        if [ -s ml_requirements.txt ]; then
            pip install -r ml_requirements.txt

            if [ $? -ne 0 ]; then
                print_message "warning" "Some ML libraries failed to install."
            else
                print_message "success" "ML libraries installed successfully"
            fi
        else
            print_message "info" "No ML libraries found in requirements.txt"
        fi
        rm ml_requirements.txt
    fi
fi

# Clean cache
clean_pip_cache

# STAGE 6: Install PyTorch (largest component)
if [ "$STAGE_TORCH" = true ]; then
    # Check disk space again
    available_space=$(check_disk_space)
    if [ "$available_space" -lt 800 ]; then
        print_message "warning" "Low disk space (${available_space}MB). Not enough for PyTorch."
        print_message "info" "Skipping PyTorch installation."
    else
        print_message "info" "Stage 6: Installing PyTorch..."

        # Extract PyTorch
        grep "torch" requirements.txt > torch_requirements.txt

        if [ -s torch_requirements.txt ]; then
            pip install -r torch_requirements.txt

            if [ $? -ne 0 ]; then
                print_message "warning" "PyTorch installation failed."
                print_message "info" "You can try installing it manually later with: pip install torch"
            else
                print_message "success" "PyTorch installed successfully"
            fi
        else
            print_message "info" "No PyTorch requirement found in requirements.txt"
        fi
        rm torch_requirements.txt
    fi
fi

# Final cache cleanup
clean_pip_cache

# STAGE 7: Download additional files if needed
if [ "$STAGE_STANDARD" = true ]; then
    print_message "info" "Stage 7: Downloading additional files..."

    # Checkout additional files
    git sparse-checkout add app/tool app/sandbox run_web_app.py run_mcp.py run_flow.py examples

    print_message "success" "Additional files downloaded successfully"
fi

# STAGE 8: Configure the system
if [ "$STAGE_CONFIG" = true ]; then
    print_message "info" "Stage 8: Setting up configuration..."

    # Create config directory
    mkdir -p config

    # Copy example config
    if [ ! -f "config/config.toml" ] && [ -f "config/config.example.toml" ]; then
        cp config/config.example.toml config/config.toml
        print_message "info" "Created config.toml from example"
    elif [ ! -f "config/config.example.toml" ]; then
        # Create a minimal config file
        cat > config/config.toml << EOL
# Global LLM configuration
[llm]
model = "gpt-4o"
base_url = "https://api.openai.com/v1"
api_key = "sk-..."  # Replace with your actual API key
max_tokens = 4096
temperature = 0.0
EOL
        print_message "info" "Created a minimal config.toml file"
    fi

    print_message "success" "Configuration setup completed"
fi

# Summary of installation
print_message "info" "✨ OpenManus Installation Summary ✨"
echo "-------------------------------------"
echo "Installation directory: $(pwd)"
echo "Virtual environment: $ENV_PATH"
echo ""
echo "Components installed:"
[ "$STAGE_BASIC" = true ] && echo "✅ Core files and basic dependencies"
[ "$STAGE_STANDARD" = true ] && echo "✅ Standard libraries"
[ "$STAGE_ML" = true ] && echo "✅ Machine Learning libraries"
[ "$STAGE_TORCH" = true ] && echo "✅ PyTorch"
[ "$STAGE_CONFIG" = true ] && echo "✅ Configuration"

[ "$STAGE_STANDARD" = false ] && echo "❌ Standard libraries (skipped)"
[ "$STAGE_ML" = false ] && echo "❌ Machine Learning libraries (skipped)"
[ "$STAGE_TORCH" = false ] && echo "❌ PyTorch (skipped)"

echo ""
print_message "success" "OpenManus installation complete!"
echo ""
echo "To start using OpenManus:"
echo "1. Edit config/config.toml to add your API keys"
echo "2. Run 'python main.py' to start OpenManus"

if [ "$STAGE_STANDARD" = true ]; then
    echo "3. For the web dashboard, run 'python run_web_app.py'"
fi

if [ "$STAGE_STANDARD" = false ]; then
    echo ""
    print_message "info" "Note: You installed a minimal version. To get full functionality:"
    echo "Run the installer again with the --install-dir=$INSTALL_DIR option to add more components."
fi

if [ "$STAGE_TORCH" = false ] && [ "$STAGE_ML" = true ]; then
    echo ""
    print_message "info" "Note: PyTorch was not installed."
    echo "To install PyTorch later, run: pip install torch"
fi
