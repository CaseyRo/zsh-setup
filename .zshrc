#!/usr/bin/env zsh
# shellcheck disable=SC1090,SC2034
# OPENSPEC:START
# OpenSpec shell completions — fpath only; compinit runs separately
fpath=("$HOME/.local/share/zsh-plugins/completions" "${fpath[@]}")
fpath+=(~/.zfunc)
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
ZSH_SETUP_FOLDER=$(dirname "$(realpath "$HOME/.zshrc")")
ZSH_SETUP_PRELOAD_CONFIGS_FOLDER=${ZSH_SETUP_FOLDER}/preload_configs
ZSH_SETUP_MODULES_FOLDER=${ZSH_SETUP_FOLDER}/modules

BASE_FOLDERS=("$ZSH_SETUP_PRELOAD_CONFIGS_FOLDER" "$ZSH_SETUP_MODULES_FOLDER")

# 1b. TERMINAL COMPATIBILITY
# Ghostty sets TERM=xterm-ghostty, but most remote hosts and multiplexers
# (byobu, tmux, screen) lack that terminfo entry. Fall back gracefully.
if [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty &>/dev/null; then
    export TERM=xterm-256color
fi

# 2. OS DETECTION
OS_FOLDER=""
OS_SUBFOLDER=""

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
OS_SCRIPT_FOLDERS=("common")
if [[ -n "$OS_FOLDER" ]]; then
    OS_SCRIPT_FOLDERS+=("$OS_FOLDER")
    if [[ -n "$OS_SUBFOLDER" ]]; then
        OS_SCRIPT_FOLDERS+=("$OS_FOLDER/$OS_SUBFOLDER")
    fi
fi

# Export for use in modules
export ZSH_SETUP_OS_FOLDER="$OS_FOLDER"
export ZSH_SETUP_OS_SUBFOLDER="$OS_SUBFOLDER"

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

# Locale, common exports, and tail-init (atuin, zoxide) live in:
#   preload_configs/common/env.sh   — locale, aliases, PATH extensions
#   modules/common/zz_atuin.sh      — atuin (loads last to win Ctrl+R)
#   modules/common/zz_zoxide.sh     — zoxide (strictly last; overrides cd)
