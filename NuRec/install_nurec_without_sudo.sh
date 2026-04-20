#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
NUREC_IMAGE="docker.io/carlasimulator/nvidia-nurec-grpc:0.2.0"
DATASET_REPO="nvidia/PhysicalAI-Autonomous-Vehicles-NuRec"
DATASET_DIR="PhysicalAI-Autonomous-Vehicles-NuRec"
DOCKER_CMD="docker" # Default docker command

# Resolve CARLA_ROOT assuming this script is in CARLA_ROOT/PythonAPI/examples/nvidia/nurec/
CARLA_ROOT="$(cd "../../../.." && pwd)"

# --- Functions ---

command_exists() { 
    command -v "$1" >/dev/null 2>&1;
}

ask_docker_sudo() {
    local CYAN='\033[0;36m'
    local WHITE='\033[1;37m'
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    echo "" >&2
    echo -e "${CYAN}============================================================${NC}" >&2
    echo -e "${WHITE}                 🐳 ${YELLOW}DOCKER PERMISSIONS${WHITE} 🐳${NC}" >&2
    echo -e "${CYAN}============================================================${NC}" >&2
    echo -e "${WHITE}If you are not in the 'docker' group, you need 'sudo' to run Docker.${NC}" >&2
    echo -ne "${WHITE}Do you need to run Docker with sudo? [y/N]: ${NC}" >&2
    read -r use_sudo
    echo >&2
    
    if [[ "$use_sudo" =~ ^[Yy]$ ]]; then
        DOCKER_CMD="sudo docker"
        echo -e "${GREEN}✅ Docker will run with sudo.${NC}" >&2
    else
        DOCKER_CMD="docker"
        echo -e "${GREEN}✅ Docker will run without sudo (default).${NC}" >&2
    fi
    echo "" >&2
}

check_hf_dataset() {
    if [ -d "$DATASET_DIR" ]; then
        return 0
    fi
    return 1
}

check_NuRec_container() {
    if $DOCKER_CMD images | grep -q "$1"; then
        return 0
    fi
    return 1
}

validate_hf_pat() {
    if [[ ! $1 =~ ^hf_[a-zA-Z0-9]{32,}$ ]]; then
        echo "Error: Invalid HuggingFace PAT format" >&2
        return 1
    fi
    return 0
}

get_hf_pat() {
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local CYAN='\033[0;36m'
    local WHITE='\033[1;37m'
    local NC='\033[0m'
    
    echo "" >&2
    echo -e "${CYAN}============================================================${NC}" >&2
    echo -e "${WHITE}              🔑 ${YELLOW}HUGGINGFACE AUTHENTICATION REQUIRED${WHITE} 🔑${NC}" >&2
    echo -e "${CYAN}============================================================${NC}" >&2
    echo "" >&2
    echo -e "${WHITE}To download the dataset, you need a ${YELLOW}HuggingFace Personal Access Token${WHITE}.${NC}" >&2
    echo "" >&2
    echo -e "${BLUE}📍 If you don't have a token yet:${NC}" >&2
    echo -e "${WHITE}   1. Visit: ${CYAN}https://huggingface.co/settings/tokens${NC}" >&2
    echo -e "${WHITE}   2. Click ${YELLOW}'New token'${NC}" >&2
    echo -e "${WHITE}   3. Choose ${GREEN}'Read'${WHITE} permissions${NC}" >&2
    echo -e "${WHITE}   4. Copy the generated token${NC}" >&2
    echo "" >&2
    echo -e "${YELLOW}⚠️  Your input will be hidden for security${NC}" >&2
    echo "" >&2
    
    echo -ne "${PURPLE}🔐 Enter your HuggingFace Personal Access Token: ${NC}" >&2
    read -s hf_pat
    echo >&2
    echo "" >&2

    if ! validate_hf_pat "$hf_pat"; then
        echo -e "${RED}❌ Invalid token format. Please try again.${NC}" >&2
        echo "" >&2
        return 1
    fi
    
    echo -e "${GREEN}✅ Token validated successfully!${NC}" >&2
    echo "" >&2
    echo "$hf_pat"
    return 0
}

setup_direnv() {
    echo "Configuring direnv in CARLA_ROOT ($CARLA_ROOT)..."
    local envrc_path="$CARLA_ROOT/.envrc"

    if ! command_exists direnv; then
        echo "❌ Error: direnv is not installed. Please install it first."
        exit 1
    fi

    # Create or update .envrc
    if [ ! -f "$envrc_path" ]; then
        echo "unset PYTHONPATH" >> "$envrc_path"
        echo "layout python3" >> "$envrc_path"
        echo "export NUREC_IMAGE=\"$NUREC_IMAGE\"" >> "$envrc_path"
        echo "export VK_ICD_FILENAMES=\"$VK_ICD_FILENAMES\"" >> "$envrc_path"
        echo "✅ Created .envrc in $CARLA_ROOT"
    else
        # Safely append if missing
        if ! grep -q "^unset PYTHONPATH" "$envrc_path"; then
            echo "unset PYTHONPATH" >> "$envrc_path"
        fi
        if ! grep -q "^layout python" "$envrc_path"; then
            echo "layout python3" >> "$envrc_path"
        fi
        if ! grep -q "^export NUREC_IMAGE=" "$envrc_path"; then
            echo "export NUREC_IMAGE=\"$NUREC_IMAGE\"" >> "$envrc_path"
        fi
        if ! grep -q "^export VK_ICD_FILENAMES=" "$envrc_path"; then
            echo "export VK_ICD_FILENAMES=\"$VK_ICD_FILENAMES\"" >> "$envrc_path"
        fi
        echo "✅ Updated existing .envrc in $CARLA_ROOT"
    fi

    # Allow direnv
    echo "Authorizing direnv..."
    direnv allow "$CARLA_ROOT"

    # Load direnv into the CURRENT bash execution context
    # This ensures the pip installs further down happen inside the isolated virtual environment!
    eval "$(direnv export bash)"
    
    # Verify it loaded
    if [[ -z "${VIRTUAL_ENV:-}" && -z "${DIRENV_DIR:-}" ]]; then
        echo "❌ Error: direnv virtual environment failed to activate."
        exit 1
    else
        echo "✅ Virtual environment active!"
    fi
}

# --- Main Execution ---

echo "🚀 Starting NuRec Installation"

# 0. Ask for Docker Permissions
ask_docker_sudo

# 1. Pull NuRec GRPC Container
echo "Checking NuRec GRPC container..."
if check_NuRec_container "$NUREC_IMAGE"; then
    echo "NuRec GRPC container already exists, skipping download."
else
    echo "Initiating NuRec GRPC Container Download..."
    $DOCKER_CMD pull "$NUREC_IMAGE" || {
        echo "❌ Error: Failed to download NuRec GRPC Container"
        exit 1
    }
fi

# 2. Handle HuggingFace Dataset
echo "Checking HuggingFace dataset..."
if check_hf_dataset; then
    echo "HuggingFace dataset already exists, skipping download."
else
    echo "Installing HuggingFace CLI..."
    python3 -m pip install --upgrade huggingface_hub || {
        echo "❌ Error: Failed to install HuggingFace CLI"
        exit 1
    }

    # Get and validate HuggingFace PAT
    hf_pat=$(get_hf_pat)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Strip whitespace
    hf_pat=$(echo "$hf_pat" | tr -d '\n\r' | xargs)
    
    echo "Authenticating with HuggingFace..."
    python3 -c "from huggingface_hub import login; login(token='$hf_pat')" || {
        echo "❌ Error: Failed to authenticate with HuggingFace"
        exit 1
    }
    
    echo "Downloading dataset..."
    # python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$DATASET_REPO', repo_type='dataset', local_dir='$DATASET_DIR')" || {
    python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$DATASET_REPO', repo_type='dataset', local_dir='$DATASET_DIR', revision='25.07', allow_patterns='sample_set/25.07_release/Batch0001/026d6a39-bd8f-4175-bc61-fe50ed0403a3/026d6a39-bd8f-4175-bc61-fe50ed0403a3.usdz')" || {
        echo "❌ Error: Failed to download the NuRec dataset"
        exit 1
    }
fi

# 3. Set Virtual Env & Environment Variables
echo "Configuring virtual environment and environment variables..."
setup_direnv

# 4. Install Python dependencies
# (Because of the `eval` command in setup_direnv, all of these 
# pip installs will now correctly target the direnv virtual environment)
echo "Installing Python dependencies..."

echo "🐍 Installing base dependencies..."
python -m pip install pygame numpy nvidia-nvtiff-cu12 nvidia-nvjpeg-cu12 nvidia-nvjpeg2k-cu12 imageio pyyaml==6.0.2 || {
    echo "❌ Error: Failed to install base dependencies"
    exit 1
}

echo "🔧 Pinning setuptools to fix grpcio-tools pkg_resources error..."
python -m pip install "setuptools<70.0.0" grpcio grpcio-tools

echo "Installing Carla Wheel..."
WHEEL=$(ls ../../../carla/dist/carla-0.9.16-cp310-cp310-*.whl 2>/dev/null | head -n 1) || true
if [ -n "$WHEEL" ]; then
    python -m pip install "${WHEEL}" || {
        echo "❌ Error: Failed to install Carla Wheel"
        exit 1
    }
else
    echo "⚠️ Warning: Carla Wheel not found. Skipping."
fi

echo "Installing project requirements..."
if [ -f "requirements.txt" ]; then 
    python -m pip install -r requirements.txt || exit 1
fi
if [ -f "nre/grpc/requirements.txt" ]; then 
    python -m pip install -r nre/grpc/requirements.txt || exit 1
fi

if [ -f "nre/grpc/update_generated.py" ]; then
    echo "🛠️ Generating GRPC files..."
    python nre/grpc/update_generated.py || {
        echo "❌ Error: Failed to update generated GRPC files"
        exit 1
    }
fi

# Make script executable
chmod +x "$0"

# 5. Final Notice
echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🔔 IMPORTANT: direnv & Virtual Environment Setup"
echo "================================================="
echo "An .envrc file was created/updated in $CARLA_ROOT"
echo ""
echo "To automatically load the NUREC_IMAGE variable and Python virtual"
echo "environment whenever you cd into CARLA_ROOT or its subdirectories,"
echo "you must hook direnv into your shell (if you haven't already)."
echo ""
echo "► If you use Bash, add this line to your ~/.bashrc:"
echo "    eval \"\$(direnv hook bash)\""
echo ""
echo "► If you use Zsh, add this line to your ~/.zshrc:"
echo "    eval \"\$(direnv hook zsh)\""
echo ""
echo "After adding the line, restart your terminal or run:"
echo "    source ~/.bashrc  # (or ~/.zshrc)"
echo ""
echo "Once active, you can verify everything is working by running:"
echo "    echo \$NUREC_IMAGE"
echo "    which python"
