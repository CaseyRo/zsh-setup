# ============================================================================
# Modern CLI tool integrations & shortcuts
# ============================================================================
# Wrappers and aliases for newer terminal tools added to packages.sh. Every
# block is guarded with `command -v` so shells on machines that don't have a
# given tool still start cleanly.

# --- glow: render markdown in the terminal ---------------------------------
if command -v glow >/dev/null 2>&1; then
    alias md="glow"                # md <file.md> — pretty-print markdown
    alias readme="glow README.md"  # quick-read the current repo's README
fi

# --- yazi: terminal file manager -------------------------------------------
# `y` launches yazi and cd's the shell to wherever you quit (official wrapper).
if command -v yazi >/dev/null 2>&1; then
    y() {
        local tmp cwd
        tmp="$(mktemp -t yazi-cwd.XXXXXX)"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
            builtin cd -- "$cwd" || return
        fi
        rm -f -- "$tmp"
    }
fi

# --- ouch: compress/decompress any archive format --------------------------
if command -v ouch >/dev/null 2>&1; then
    alias unpack="ouch decompress"   # unpack <archive>  (zip/tar/gz/7z/…)
    alias pack="ouch compress"       # pack <files…> <out.tar.gz>
fi

# --- xh: HTTPie-style HTTP client ------------------------------------------
# Provide http/https shims only if the real HTTPie isn't already installed.
if command -v xh >/dev/null 2>&1; then
    command -v http  >/dev/null 2>&1 || alias http="xh"
    command -v https >/dev/null 2>&1 || alias https="xh --https"
fi

# --- jnv: interactive JSON viewer/filter (live jq) -------------------------
if command -v jnv >/dev/null 2>&1; then
    alias jqi="jnv"                  # jqi <file.json>  or:  cmd | jnv
fi

# --- df: friendlier disk usage ---------------------------------------------
# dysk (Linux-only) is richest; duf is the cross-platform fallback.
if command -v dysk >/dev/null 2>&1; then
    alias df="dysk"
elif command -v duf >/dev/null 2>&1; then
    alias df="duf"
fi

# --- jj (Jujutsu): Git-compatible VCS --------------------------------------
if command -v jj >/dev/null 2>&1; then
    alias jjs="jj status"
    alias jjl="jj log"
    alias jjd="jj diff"
fi
