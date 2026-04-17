# ============================================================================
# Common Initialization
# ============================================================================
# Loaded on all systems before OS-specific configs

# Machine detection (available for use in other modules)
MACHINE_HOSTNAME=$(hostname)
MACHINE_OS=$(uname)
MACHINE_USER=$(whoami)
export MACHINE_HOSTNAME MACHINE_OS MACHINE_USER

# History configuration
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
# shellcheck disable=SC2034  # SAVEHIST is read by zsh internals
SAVEHIST=50000

setopt INC_APPEND_HISTORY        # Write immediately, not on shell exit
setopt SHARE_HISTORY             # Share history across all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming
setopt HIST_IGNORE_DUPS          # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate when new one added
setopt HIST_FIND_NO_DUPS         # Don't show duplicates in search
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicates to file
setopt HIST_VERIFY               # Show expanded history before executing
setopt EXTENDED_HISTORY          # Record timestamp and duration

# Completion system — compinit runs after all fpath entries are set
zstyle :compinstall filename '$HOME/.zshrc'
