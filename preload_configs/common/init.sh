# ============================================================================
# Common Initialization
# ============================================================================
# Loaded on all systems before OS-specific configs

# Machine detection (available for use in other modules)
export MACHINE_HOSTNAME=$(hostname)
export MACHINE_OS=$(uname)
export MACHINE_USER=$(whoami)

# History configuration
HISTFILE=$HOME/dotfiles/.zsh_history
HISTSIZE=50000
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

# Completion system — compinit runs once via Oh-My-Zsh after all fpath entries are set
zstyle :compinstall filename '$HOME/.zshrc'
