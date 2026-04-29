#!/bin/bash
# shellcheck disable=SC1083
# ============================================================================
# ZSH-Setup Doctor — Health check for your zsh-setup installation
# ============================================================================
# Usage: bash scripts/doctor.sh
#        or via alias: zsh-doctor (if modules/common/functions.sh is loaded)
# ============================================================================

set -e

# Colors
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

PASS="${GREEN}✓${RESET}"
FAIL="${RED}✗${RESET}"
WARN="${YELLOW}⚠${RESET}"

score=0
total=0
warnings=0

check_pass() {
    echo "  $PASS $1"
    score=$((score + 1))
    total=$((total + 1))
}

check_fail() {
    echo "  $FAIL $1"
    total=$((total + 1))
}

check_warn() {
    echo "  $WARN $1"
    warnings=$((warnings + 1))
    total=$((total + 1))
}

# Resolve zsh-setup directory
if [[ -n "$ZSH_SETUP_FOLDER" ]]; then
    SETUP_DIR="$ZSH_SETUP_FOLDER"
elif [[ -L "$HOME/.zshrc" ]]; then
    SETUP_DIR="$(dirname "$(readlink "$HOME/.zshrc")")"
elif [[ -d "$HOME/.zsh-setup" ]]; then
    SETUP_DIR="$HOME/.zsh-setup"
else
    SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

echo ""
echo "${BOLD}ZSH-Setup Doctor${RESET}"
echo "${DIM}Checking installation health...${RESET}"
echo ""

# ============================================================================
# 1. Symlinks
# ============================================================================
echo "${CYAN}Symlinks${RESET}"

if [[ -L "$HOME/.zshrc" ]]; then
    target="$(readlink "$HOME/.zshrc")"
    if [[ -f "$target" ]]; then
        check_pass "\$HOME/.zshrc → $target"
    else
        check_fail "\$HOME/.zshrc symlink is broken → $target"
    fi
elif [[ -f "$HOME/.zshrc" ]]; then
    check_warn "\$HOME/.zshrc exists but is not a symlink (managed manually?)"
else
    check_fail "\$HOME/.zshrc is missing"
fi

# Starship config
if [[ -f "$SETUP_DIR/configs/starship.toml" ]]; then
    starship_target="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
    if [[ -L "$starship_target" ]]; then
        check_pass "starship.toml symlinked"
    elif [[ -f "$starship_target" ]]; then
        check_warn "starship.toml exists but is not a symlink"
    fi
fi

# Topgrade config
topgrade_target="${XDG_CONFIG_HOME:-$HOME/.config}/topgrade.toml"
if [[ -L "$topgrade_target" ]]; then
    check_pass "topgrade.toml symlinked"
elif [[ -f "$SETUP_DIR/configs/topgrade.toml" ]]; then
    check_warn "topgrade.toml exists in repo but is not symlinked"
fi

echo ""

# ============================================================================
# 2. Core Tools
# ============================================================================
echo "${CYAN}Core Tools${RESET}"

core_tools=(zsh git curl)
for tool in "${core_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        check_pass "$tool"
    else
        check_fail "$tool not found"
    fi
done

# Shell-enhancing tools
shell_tools=(eza bat fd fzf zoxide starship btop)
for tool in "${shell_tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        check_pass "$tool"
    else
        # batcat / fdfind alternatives on Debian
        if [[ "$tool" == "bat" ]] && command -v batcat &>/dev/null; then
            check_pass "$tool (as batcat)"
        elif [[ "$tool" == "fd" ]] && command -v fdfind &>/dev/null; then
            check_pass "$tool (as fdfind)"
        else
            check_warn "$tool not installed"
        fi
    fi
done

echo ""

# ============================================================================
# 3. Modules Loading
# ============================================================================
echo "${CYAN}Modules${RESET}"

module_dir="$SETUP_DIR/modules/common"
if [[ -d "$module_dir" ]]; then
    module_count=$(find "$module_dir" -maxdepth 1 -name '*.sh' ! -name '#*' | wc -l | tr -d ' ')
    check_pass "$module_count common modules found"
else
    check_fail "modules/common/ directory missing"
fi

# Check OS-specific modules exist for current platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    os_module_dir="$SETUP_DIR/modules/macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_module_dir="$SETUP_DIR/modules/linux"
fi

if [[ -n "$os_module_dir" ]] && [[ -d "$os_module_dir" ]]; then
    os_count=$(find "$os_module_dir" -name '*.sh' ! -name '#*' | wc -l | tr -d ' ')
    check_pass "$os_count OS-specific modules found"
elif [[ -n "$os_module_dir" ]]; then
    check_warn "OS module directory missing: $os_module_dir"
fi

echo ""

# ============================================================================
# 4. PATH Sanity
# ============================================================================
echo "${CYAN}PATH${RESET}"

# Check for common expected paths
expected_paths=("$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.local/bin")
for p in "${expected_paths[@]}"; do
    if [[ -d "$p" ]]; then
        if echo "$PATH" | tr ':' '\n' | grep -q "^${p}$"; then
            check_pass "$p in PATH"
        else
            check_warn "$p exists but not in PATH"
        fi
    fi
done

echo ""

# ============================================================================
# 5. Git Repo Health
# ============================================================================
echo "${CYAN}Repository${RESET}"

if [[ -d "$SETUP_DIR/.git" ]]; then
    check_pass "Git repo intact"

    # Check for uncommitted changes
    if git -C "$SETUP_DIR" diff --quiet 2>/dev/null && git -C "$SETUP_DIR" diff --cached --quiet 2>/dev/null; then
        check_pass "No uncommitted changes"
    else
        check_warn "Uncommitted changes in zsh-setup repo"
    fi

    # Check if behind remote
    git -C "$SETUP_DIR" fetch --quiet 2>/dev/null || true
    local_sha=$(git -C "$SETUP_DIR" rev-parse HEAD 2>/dev/null)
    remote_sha=$(git -C "$SETUP_DIR" rev-parse '@{upstream}' 2>/dev/null || echo "")
    if [[ -n "$remote_sha" ]]; then
        if [[ "$local_sha" == "$remote_sha" ]]; then
            check_pass "Up to date with remote"
        else
            behind=$(git -C "$SETUP_DIR" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
            if [[ "$behind" -gt 0 ]]; then
                check_warn "$behind commits behind remote"
            else
                check_pass "Ahead of remote (unpushed commits)"
            fi
        fi
    fi
else
    check_fail "Not a git repository: $SETUP_DIR"
fi

# Install state
if [[ -f "$SETUP_DIR/.install-state" ]]; then
    check_pass "Install state file present"
else
    check_warn "No .install-state file (run install.sh to persist preferences)"
fi

echo ""

# ============================================================================
# 6. Shell Config
# ============================================================================
echo "${CYAN}Shell${RESET}"

current_shell=$(basename "$SHELL")
if [[ "$current_shell" == "zsh" ]]; then
    check_pass "Default shell is zsh"
else
    check_warn "Default shell is $current_shell (expected zsh)"
fi

if command -v starship &>/dev/null; then
    check_pass "Starship prompt installed"
else
    check_fail "Starship prompt not found"
fi

echo ""

# ============================================================================
# 7. Syncthing
# ============================================================================
echo "${CYAN}Syncthing${RESET}"

if command -v syncthing &>/dev/null; then
    check_pass "syncthing binary"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        st_config="$HOME/Library/Application Support/Syncthing"
    elif [[ -d "$HOME/.local/state/syncthing" ]]; then
        st_config="$HOME/.local/state/syncthing"
    else
        st_config="${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"
    fi

    if [[ -f "$st_config/.zsh-setup-managed" ]]; then
        check_pass "managed by zsh-setup"
    elif [[ -d "$st_config" ]]; then
        check_warn "config exists but not managed by zsh-setup ($st_config)"
    else
        check_warn "no config directory yet — run install.sh to bootstrap"
    fi

    if curl -fsS --max-time 2 http://127.0.0.1:8384/rest/system/ping &>/dev/null; then
        check_pass "API reachable on http://127.0.0.1:8384"
    else
        check_warn "API not reachable (service stopped?)"
    fi
else
    check_warn "syncthing not installed"
fi

echo ""

# ============================================================================
# 7b. Atuin executable bit
# ============================================================================
# `command -v atuin` filters by executability in zsh but not always in bash —
# so a 664 atuin in PATH passes "Core Tools" while breaking the actual shell.
# Probe the known install paths explicitly and assert -x.
echo "${CYAN}Atuin${RESET}"

atuin_paths=()
[[ -f "$HOME/.atuin/bin/atuin" ]] && atuin_paths+=("$HOME/.atuin/bin/atuin")
if command -v brew &>/dev/null; then
    brew_atuin="$(brew --prefix atuin 2>/dev/null)/bin/atuin"
    [[ -f "$brew_atuin" ]] && atuin_paths+=("$brew_atuin")
fi
path_atuin=$(command -v atuin 2>/dev/null)
if [[ -n "$path_atuin" ]]; then
    already=false
    for existing in "${atuin_paths[@]}"; do
        [[ "$existing" == "$path_atuin" ]] && already=true && break
    done
    [[ "$already" == false ]] && atuin_paths+=("$path_atuin")
fi

if (( ${#atuin_paths[@]} == 0 )); then
    check_warn "atuin not installed"
else
    for atuin_bin in "${atuin_paths[@]}"; do
        if [[ -x "$atuin_bin" ]]; then
            check_pass "atuin executable: $atuin_bin"
        else
            check_fail "atuin not executable: $atuin_bin — fix: chmod +x $atuin_bin"
        fi
    done
fi

echo ""

# ============================================================================
# 8. HOME Ownership
# ============================================================================
echo "${CYAN}HOME Ownership${RESET}"

me=$(id -un 2>/dev/null || echo "")
own_mismatched=0
own_checked=0
own_sample=""
# Probe path list mirrors check_home_ownership_sweep in install/utils.sh —
# keep them in sync so doctor and installer flag the same drift.
for p in "$HOME" "$HOME/.config" "$HOME/.local" "$HOME/.cache" "$HOME/.cargo" "$HOME/.ssh" "$HOME/.zsh-setup"; do
    [[ -e "$p" ]] || continue
    owner=$(stat -c '%U' "$p" 2>/dev/null || stat -f '%Su' "$p" 2>/dev/null)
    own_checked=$((own_checked + 1))
    if [[ -n "$owner" && "$owner" != "$me" ]]; then
        own_mismatched=$((own_mismatched + 1))
        own_sample="$owner"
    fi
done

if [[ -z "$me" ]] || (( own_checked == 0 )); then
    check_warn "Could not probe HOME ownership"
elif (( own_mismatched == 0 )); then
    check_pass "HOME owned by $me"
elif (( own_mismatched * 2 <= own_checked )); then
    check_warn "$own_mismatched of $own_checked HOME paths owned by other users"
else
    check_fail "$own_mismatched of $own_checked HOME paths owned by '$own_sample' — run: sudo chown -R $me:$me \$HOME"
fi

echo ""

# ============================================================================
# Score
# ============================================================================
echo "${BOLD}────────────────────────────────${RESET}"
pct=$((score * 100 / total))
if [[ $pct -ge 90 ]]; then
    color="$GREEN"
elif [[ $pct -ge 70 ]]; then
    color="$YELLOW"
else
    color="$RED"
fi
echo "${BOLD}Score: ${color}${score}/${total} (${pct}%)${RESET}"
if [[ $warnings -gt 0 ]]; then
    echo "${DIM}$warnings warning(s)${RESET}"
fi
echo ""
