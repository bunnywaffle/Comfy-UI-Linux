#!/bin/bash

# ComfyUI Interactive Installation Script for Linux
# This script guides you through installing ComfyUI with user choices

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt user for yes/no
prompt_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Welcome message
clear
echo "=========================================="
echo "  ComfyUI Installation Script for Linux  "
echo "=========================================="
echo ""

# Step 1: Choose action - Launch or Install
print_info "What would you like to do?"
echo "1) Install ComfyUI (First time setup)"
echo "2) Launch existing ComfyUI installation"
read -p "Enter your choice (1 or 2): " action_choice

if [[ "$action_choice" != "1" && "$action_choice" != "2" ]]; then
    print_error "Invalid choice. Exiting."
    exit 1
fi

# If user wants to launch existing installation
if [ "$action_choice" == "2" ]; then
    print_info "Launch existing ComfyUI installation"
    echo ""

    # Function to find and activate virtual environment
    find_and_activate_venv() {
        local venv_found=false

        # Common virtual environment names and locations
        local venv_paths=(
            "comfy-env"
            "venv"
            "comfyui"
            ".venv"
            "../comfy-env"
            "../venv"
            "$HOME/comfy-env"
            "$HOME/Documents/comfyui"
        )

        for venv_path in "${venv_paths[@]}"; do
            if [ -d "$venv_path" ] && [ -f "$venv_path/bin/activate" ]; then
                print_info "Found virtual environment at: $venv_path"
                print_info "Activating virtual environment..."
                source "$venv_path/bin/activate"
                print_success "Virtual environment activated"
                venv_found=true
                break
            fi
        done

        if [ "$venv_found" = false ]; then
            print_warning "No virtual environment found in common locations."
            if prompt_yes_no "Do you want to specify a custom virtual environment path?"; then
                read -p "Enter the path to your virtual environment: " custom_venv
                if [ -d "$custom_venv" ] && [ -f "$custom_venv/bin/activate" ]; then
                    print_info "Activating virtual environment..."
                    source "$custom_venv/bin/activate"
                    print_success "Virtual environment activated"
                else
                    print_warning "Virtual environment not found at specified path. Continuing without activation..."
                fi
            fi
        fi
    }

    # Try to find and activate virtual environment first
    find_and_activate_venv

    # Check if comfy-cli is installed
    if command -v comfy &> /dev/null; then
        print_success "Comfy CLI detected"

        print_info "Choose launch mode:"
        echo "1) Normal mode"
        echo "2) Background mode"
        echo "3) Custom (specify options)"
        echo "4) Check workspace location"
        read -p "Enter your choice (1-4): " launch_choice

        case $launch_choice in
            1)
                print_info "Launching ComfyUI..."
                print_info "Access it at: http://localhost:8188"
                comfy launch
                ;;
            2)
                print_info "Launching ComfyUI in background..."
                comfy launch --background
                print_success "ComfyUI is running in background"
                print_info "Access it at: http://localhost:8188"
                print_info "Stop it with: comfy stop"
                ;;
            3)
                read -p "Enter custom launch options (e.g., -- --listen 0.0.0.0 --port 8080): " custom_opts
                print_info "Launching ComfyUI with custom options..."
                comfy launch $custom_opts
                ;;
            4)
                print_info "ComfyUI workspace locations:"
                comfy which
                comfy --recent which 2>/dev/null || true
                echo ""
                if prompt_yes_no "Do you want to launch now?"; then
                    comfy launch
                fi
                ;;
        esac
    else
        # Look for manual installation
        print_warning "Comfy CLI not found. Looking for manual installation..."

        # Common ComfyUI installation paths
        comfyui_paths=(
            "ComfyUI"
            "comfyui"
            "$HOME/comfy"
            "$HOME/ComfyUI"
            "$HOME/Documents/comfyui"
            "./ComfyUI"
        )

        found_comfyui=false
        for path in "${comfyui_paths[@]}"; do
            if [ -d "$path" ] && [ -f "$path/main.py" ]; then
                cd "$path"
                print_success "Found ComfyUI installation at: $path"
                found_comfyui=true
                break
            fi
        done

        if [ "$found_comfyui" = false ]; then
            print_warning "ComfyUI installation not found in common locations."
            if prompt_yes_no "Do you want to specify a custom ComfyUI path?"; then
                read -p "Enter the path to your ComfyUI installation: " custom_path
                if [ -d "$custom_path" ] && [ -f "$custom_path/main.py" ]; then
                    cd "$custom_path"
                    print_success "Found ComfyUI at: $custom_path"
                else
                    print_error "Could not find ComfyUI installation at specified path."
                    print_info "Please run this script again and choose 'Install' option."
                    exit 1
                fi
            else
                print_error "Could not find ComfyUI installation."
                print_info "Please run this script again and choose 'Install' option."
                exit 1
            fi
        fi

        print_info "Launching ComfyUI..."
        print_info "Access it at: http://localhost:8188"
        python main.py
    fi

    exit 0
fi

# Step 2: Choose installation method
print_info "Choose installation method:"
echo "1) Comfy CLI (Recommended - Simple and fast)"
echo "2) From source code (Traditional manual method)"
read -p "Enter your choice (1 or 2): " install_method

if [[ "$install_method" != "1" && "$install_method" != "2" ]]; then
    print_error "Invalid choice. Exiting."
    exit 1
fi

# Step 2: Detect Linux distribution
print_info "Detecting Linux distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    print_success "Detected: $PRETTY_NAME"
else
    print_warning "Could not detect distribution automatically."
    echo "Please select your distribution:"
    echo "1) Ubuntu/Debian"
    echo "2) CentOS/RHEL"
    echo "3) Fedora"
    echo "4) Arch Linux"
    read -p "Enter your choice (1-4): " distro_choice
    case $distro_choice in
        1) DISTRO="ubuntu";;
        2) DISTRO="centos";;
        3) DISTRO="fedora";;
        4) DISTRO="arch";;
        *) print_error "Invalid choice. Exiting."; exit 1;;
    esac
fi

# Step 3: Check and install Python
print_info "Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    print_success "Python $PYTHON_VERSION is installed"

    # Check if version is >= 3.9
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 9 ]); then
        print_warning "Python 3.9 or higher is required. Current version: $PYTHON_VERSION"
        if prompt_yes_no "Do you want to install/upgrade Python?"; then
            case $DISTRO in
                ubuntu|debian)
                    sudo apt update
                    sudo apt install -y python3 python3-pip python3-venv
                    ;;
                centos|rhel)
                    sudo yum install -y python3 python3-pip
                    ;;
                fedora)
                    sudo dnf install -y python3 python3-pip
                    ;;
                arch)
                    sudo pacman -S --noconfirm python python-pip
                    ;;
            esac
        else
            print_error "Python 3.9+ is required. Exiting."
            exit 1
        fi
    fi
else
    print_warning "Python3 is not installed."
    if prompt_yes_no "Do you want to install Python3?"; then
        case $DISTRO in
            ubuntu|debian)
                sudo apt update
                sudo apt install -y python3 python3-pip python3-venv
                ;;
            centos|rhel)
                sudo yum install -y python3 python3-pip
                ;;
            fedora)
                sudo dnf install -y python3 python3-pip
                ;;
            arch)
                sudo pacman -S --noconfirm python python-pip
                ;;
        esac
    else
        print_error "Python3 is required. Exiting."
        exit 1
    fi
fi

# Step 4: Check and install Git
print_info "Checking Git installation..."
if ! command -v git &> /dev/null; then
    print_warning "Git is not installed."
    if prompt_yes_no "Do you want to install Git?"; then
        case $DISTRO in
            ubuntu|debian)
                sudo apt install -y git
                ;;
            centos|rhel)
                sudo yum install -y git
                ;;
            fedora)
                sudo dnf install -y git
                ;;
            arch)
                sudo pacman -S --noconfirm git
                ;;
        esac
        print_success "Git installed successfully"
    else
        print_error "Git is required. Exiting."
        exit 1
    fi
else
    print_success "Git is already installed"
fi

# Step 5: Create virtual environment
if prompt_yes_no "Do you want to create a virtual environment? (Recommended)"; then
    VENV_NAME="comfy-env"
    read -p "Enter virtual environment name (default: comfy-env): " user_venv
    if [ ! -z "$user_venv" ]; then
        VENV_NAME="$user_venv"
    fi

    print_info "Creating virtual environment: $VENV_NAME"
    python3 -m venv $VENV_NAME
    source $VENV_NAME/bin/activate
    print_success "Virtual environment created and activated"
    print_warning "Remember to activate it later with: source $VENV_NAME/bin/activate"
    USE_VENV=true
else
    USE_VENV=false
fi

# Step 6: Install based on method chosen
if [ "$install_method" == "1" ]; then
    # Comfy CLI Installation
    print_info "Installing Comfy CLI..."
    pip install comfy-cli
    print_success "Comfy CLI installed successfully"

    # Ask about auto-completion
    if prompt_yes_no "Do you want to install command-line auto-completion?"; then
        comfy --install-completion
        print_success "Auto-completion installed"
    fi

    # Choose installation directory
    print_info "Choose installation directory:"
    echo "1) Default (~/comfy)"
    echo "2) Custom directory"
    echo "3) Current directory"
    read -p "Enter your choice (1-3): " dir_choice

    INSTALL_CMD="comfy install"
    case $dir_choice in
        1)
            # Default directory
            ;;
        2)
            read -p "Enter custom installation path: " custom_path
            INSTALL_CMD="comfy --workspace=$custom_path install"
            ;;
        3)
            INSTALL_CMD="comfy --here install"
            ;;
    esac

    # Ask about ComfyUI-Manager
    if ! prompt_yes_no "Do you want to install ComfyUI-Manager? (Recommended)"; then
        INSTALL_CMD="$INSTALL_CMD --skip-manager"
    fi

    print_info "Installing ComfyUI..."
    eval $INSTALL_CMD
    print_success "ComfyUI installed successfully"

else
    # Source Code Installation
    read -p "Enter directory to clone ComfyUI (default: ./ComfyUI): " clone_dir
    if [ -z "$clone_dir" ]; then
        clone_dir="./ComfyUI"
    fi

    print_info "Cloning ComfyUI repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$clone_dir"
    cd "$clone_dir"

    if [ "$USE_VENV" = false ]; then
        if prompt_yes_no "Create virtual environment in ComfyUI directory?"; then
            python3 -m venv venv
            source venv/bin/activate
            print_success "Virtual environment created and activated"
        fi
    fi

    print_info "Installing dependencies..."
    pip install -r requirements.txt
    print_success "Dependencies installed successfully"
fi

# Step 7: GPU Support Selection
echo ""
print_info "Select GPU support:"
echo "1) NVIDIA GPU (CUDA)"
echo "2) AMD GPU (ROCm)"
echo "3) CPU only"
read -p "Enter your choice (1-3): " gpu_choice

case $gpu_choice in
    1)
        print_info "Installing PyTorch with CUDA support..."
        print_warning "This will install CUDA 12.4 support. Adjust if you have a different CUDA version."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
        print_success "CUDA support installed"
        ;;
    2)
        print_info "Installing PyTorch with ROCm support..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
        print_success "ROCm support installed"
        ;;
    3)
        print_info "Installing PyTorch for CPU only..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
        print_success "CPU support installed"
        ;;
    *)
        print_error "Invalid choice. Skipping GPU support installation."
        ;;
esac

# Step 8: Launch options
echo ""
print_success "Installation completed successfully!"
echo ""

if prompt_yes_no "Do you want to launch ComfyUI now?"; then
    if [ "$install_method" == "1" ]; then
        # Comfy CLI launch
        echo ""
        print_info "Choose launch mode:"
        echo "1) Normal mode"
        echo "2) Background mode"
        echo "3) Custom (specify options)"
        read -p "Enter your choice (1-3): " launch_choice

        case $launch_choice in
            1)
                print_info "Launching ComfyUI..."
                print_info "Access it at: http://localhost:8188"
                comfy launch
                ;;
            2)
                print_info "Launching ComfyUI in background..."
                comfy launch --background
                print_success "ComfyUI is running in background"
                print_info "Access it at: http://localhost:8188"
                print_info "Stop it with: comfy stop"
                ;;
            3)
                read -p "Enter custom launch options (e.g., -- --listen 0.0.0.0 --port 8080): " custom_opts
                comfy launch $custom_opts
                ;;
        esac
    else
        # Source code launch
        print_info "Launching ComfyUI..."
        print_info "Access it at: http://localhost:8188"
        python main.py
    fi
else
    echo ""
    print_info "To launch ComfyUI later:"
    if [ "$install_method" == "1" ]; then
        if [ "$USE_VENV" = true ]; then
            echo "  1. Activate virtual environment: source $VENV_NAME/bin/activate"
        fi
        echo "  2. Run: comfy launch"
    else
        echo "  1. Navigate to ComfyUI directory: cd $clone_dir"
        if [ "$USE_VENV" = true ]; then
            echo "  2. Activate virtual environment: source $VENV_NAME/bin/activate"
        fi
        echo "  3. Run: python main.py"
    fi
fi

echo ""
print_success "Setup complete! Enjoy using ComfyUI!"
