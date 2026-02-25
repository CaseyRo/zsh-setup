# OPENSPEC:START
# OpenSpec shell completions — fpath only; compinit runs once via Oh-My-Zsh
fpath=("/Users/caseyromkes/.oh-my-zsh/custom/completions" $fpath)
# OPENSPEC:END

# ============================================================================
# ZSH-Setup: Main Configuration Loader
# ============================================================================
# This file automatically loads configurations based on your operating system.
# - Common configs are loaded first
# - OS-specific configs are loaded afterward
# - Modules are loaded after preload_configs
#
# To add your own configs, place .sh files in the appropriate folders:
# - preload_configs/common/     - Loaded on all systems
# - preload_configs/macos/      - macOS only
# - preload_configs/linux/ubuntu/       - Ubuntu/Debian Linux
# - preload_configs/linux/raspberry-pi/ - Raspberry Pi
# - modules/common/             - Modules for all systems
# - modules/macos/              - macOS-only modules
# - modules/linux/ubuntu/       - Ubuntu-only modules
# - modules/linux/raspberry-pi/ - Raspberry Pi-only modules
#
# Files/folders starting with # are ignored (e.g., #disabled.sh)
# ============================================================================

# 1. CONFIGURATION PATHS
ZSH_SETUP_FOLDER=$(dirname $(realpath $HOME/.zshrc))
ZSH_SETUP_PRELOAD_CONFIGS_FOLDER=${ZSH_SETUP_FOLDER}/preload_configs
ZSH_SETUP_MODULES_FOLDER=${ZSH_SETUP_FOLDER}/modules

# Legacy aliases for external scripts
ZSH_Manager_FOLDER="$ZSH_SETUP_FOLDER"
ZSH_Manager_PRELOAD_CONFIGS_FOLDER="$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER"
ZSH_Manager_MODULES_FOLDER="$ZSH_SETUP_MODULES_FOLDER"

local BASE_FOLDERS=("$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER" "$ZSH_SETUP_MODULES_FOLDER")

# 2. OS DETECTION
local OS_FOLDER=""
local OS_SUBFOLDER=""

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_FOLDER="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_FOLDER="linux"
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "raspbian" ]] || [[ "$ID" == "debian" && "$(uname -m)" == "arm"* ]] || [[ -f /sys/firmware/devicetree/base/model && "$(cat /sys/firmware/devicetree/base/model 2>/dev/null)" == *"Raspberry"* ]]; then
            OS_SUBFOLDER="raspberry-pi"
        elif [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
            OS_SUBFOLDER="ubuntu"
        fi
    fi
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS_FOLDER="windows"
fi

# Build list of folders to load from (in order)
local OS_SCRIPT_FOLDERS=("common")
if [[ -n "$OS_FOLDER" ]]; then
    OS_SCRIPT_FOLDERS+=("$OS_FOLDER")
    if [[ -n "$OS_SUBFOLDER" ]]; then
        OS_SCRIPT_FOLDERS+=("$OS_FOLDER/$OS_SUBFOLDER")
    fi
fi

# Export for use in modules
export ZSH_SETUP_OS_FOLDER="$OS_FOLDER"
export ZSH_SETUP_OS_SUBFOLDER="$OS_SUBFOLDER"
export ZSH_Manager_OS_FOLDER="$ZSH_SETUP_OS_FOLDER"
export ZSH_Manager_OS_SUBFOLDER="$ZSH_SETUP_OS_SUBFOLDER"

# 3. HELPER FUNCTION
include () {
    [[ -f "$1" ]] && source "$1"
}

# 4. LOAD PATH CONFIGURATION FIRST
# Load common path config
include "$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER/common/path.sh"

# Load OS-specific path config
if [[ -n "$OS_SUBFOLDER" ]]; then
    include "$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER/$OS_FOLDER/$OS_SUBFOLDER/path.sh"
else
    include "$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER/$OS_FOLDER/path.sh"
fi

# Load user environment variables
include "$HOME/.env.sh"

# 5. LOAD PRELOAD CONFIGS THEN MODULES
for base_folder in "${BASE_FOLDERS[@]}"; do
    for os_folder in "${OS_SCRIPT_FOLDERS[@]}"; do
        folder="$base_folder/$os_folder"
        if [[ -d "$folder" ]]; then
            # Find all .sh files, excluding those starting with #
            # Skip path.sh files (already loaded above)
            find "$folder" -maxdepth 1 -type f -name "*.sh" ! -name "path.sh" ! -name "#*" -print0 2>/dev/null | sort -z | while IFS= read -r -d '' script; do
                source "$script"
            done
        fi
    done
done
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
