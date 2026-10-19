#!/bin/bash
# shellcheck shell=bash
# ============================================================================
# Hausputz — weekly Desktop/Downloads tidy-up (macOS only)
# ============================================================================
# Installs the `hausputz` agent, writes its config, puts the machine token in
# the login Keychain (from 1Password, never a file), and loads a launchd user
# agent that runs every Friday 09:00. A newly enrolled Mac starts in dry-run;
# re-running never changes the mode. On cc1 it also installs the service.
# Spec: ~/dev/hausputz/openspec/changes/hausputz-v0-1-desktop-downloads
# Opt out: ZSH_SETUP_SKIP_HAUSPUTZ=1
# ============================================================================

HAUSPUTZ_REPO="${HAUSPUTZ_REPO:-$HOME/dev/hausputz}"
HAUSPUTZ_MODULE="github.com/CaseyRo/hausputz"
HAUSPUTZ_SERVER_URL="${HAUSPUTZ_SERVER_URL:-https://cc1.onca-blenny.ts.net}"
HAUSPUTZ_UI_LOGIN="${HAUSPUTZ_UI_LOGIN:-hw4vzdv7gm@privaterelay.appleid.com}"
HAUSPUTZ_OP_ITEM="op://terminal access/Hausputz"

# Machine id: cc1 and caseys-air by name, otherwise the short host name.
hausputz_machine_id() {
    local h
    h=$(scutil --get LocalHostName 2>/dev/null | tr '[:upper:]' '[:lower:]')
    case "$h" in
        cc1*) echo "cc1" ;;
        *macbook-air*) echo "caseys-air" ;;
        *) echo "${h:-$(hostname -s | tr '[:upper:]' '[:lower:]')}" ;;
    esac
}

# Build from the local checkout when there is one, else from GitHub.
hausputz_go_install() {
    local cmd="$1"
    if [[ -f "$HAUSPUTZ_REPO/go.mod" ]]; then
        (cd "$HAUSPUTZ_REPO" && run_cmd go install "./cmd/$cmd")
    else
        GOPRIVATE="github.com/CaseyRo" run_cmd go install "$HAUSPUTZ_MODULE/cmd/$cmd@latest"
    fi
}

hausputz_load_agent() {
    local label="$1" plist="$2"
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist"
}

install_hausputz() {
    [[ "$OSTYPE" == "darwin"* ]] || return 0
    [[ -n "${ZSH_SETUP_SKIP_HAUSPUTZ:-}" ]] && return 0
    print_section "Hausputz"
    if ! command_exists go; then
        print_warning "Go not installed, skipping Hausputz"
        return 0
    fi

    local machine bin cfg_dir cfg state plist
    machine=$(hausputz_machine_id)
    bin="$(go env GOPATH)/bin/hausputz"
    cfg_dir="$HOME/.config/hausputz"
    cfg="$cfg_dir/config.json"
    state="$HOME/.local/state/hausputz"
    plist="$HOME/Library/LaunchAgents/de.cdit.hausputz.plist"

    print_step "Installing hausputz agent ($machine)"
    hausputz_go_install hausputz || { print_warning "hausputz build failed"; return 0; }

    mkdir -p "$cfg_dir" "$state"
    if [[ -f "$cfg" ]]; then
        print_skip "config (kept, mode unchanged)"
    else
        # The iCloud Desktop is shared: only cc1 owns it.
        local owned='"downloads":"~/Downloads"'
        [[ "$machine" == "cc1" ]] && owned='"desktop":"~/Desktop","downloads":"~/Downloads"'
        printf '{\n  "machine_id": "%s",\n  "server": "%s",\n  "owned": {%s},\n  "mode": "dry-run",\n  "trial": true,\n  "queue_url": "%s/"\n}\n' \
            "$machine" "$HAUSPUTZ_SERVER_URL" "$owned" "$HAUSPUTZ_SERVER_URL" > "$cfg"
        chmod 600 "$cfg"
        print_success "config written (dry-run)"
    fi

    if security find-generic-password -s hausputz -a "$machine" >/dev/null 2>&1; then
        print_skip "machine token (in Keychain)"
    elif command_exists op; then
        local tok
        if tok=$(op read "$HAUSPUTZ_OP_ITEM/$machine" 2>/dev/null) && [[ -n "$tok" ]]; then
            if security add-generic-password -U -s hausputz -a "$machine" -w "$tok" >/dev/null 2>&1; then
                print_success "machine token stored in Keychain"
            else
                print_info "Keychain not writable here (SSH session): the agent reads its token with op at run time"
            fi
            unset tok
        else
            print_warning "no 1Password field '$machine' in item Hausputz: agent runs offline until it exists"
        fi
    fi

    # Yorizon items land here untouched; Hausputz never sorts inside it.
    [[ -d "$HOME/Syncthing/yorizon" ]] && mkdir -p "$HOME/Syncthing/yorizon/to-sort"

    mkdir -p "$(dirname "$plist")"
    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>de.cdit.hausputz</string>
  <key>ProgramArguments</key><array><string>/bin/zsh</string><string>-c</string><string>source ~/.env.sh 2&gt;/dev/null; PATH=/opt/homebrew/bin:\$PATH exec "$bin" run</string></array>
  <key>StartCalendarInterval</key><dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$state/launchd.log</string>
  <key>StandardErrorPath</key><string>$state/launchd.log</string>
  <key>ProcessType</key><string>Background</string>
</dict></plist>
PLIST
    hausputz_load_agent de.cdit.hausputz "$plist" && print_success "launchd agent loaded (Fridays 09:00)"

    [[ "$machine" == "cc1" ]] && install_hausputz_server
    "$bin" status 2>/dev/null || true
}

# The service runs on cc1 only, on localhost behind `tailscale serve`.
install_hausputz_server() {
    local bin state cfg plist tokens
    bin="$(go env GOPATH)/bin/hausputz-server"
    state="$HOME/.local/state/hausputz-server"
    cfg="$HOME/.config/hausputz-server"
    tokens="$cfg/machines.json"
    plist="$HOME/Library/LaunchAgents/de.cdit.hausputz-server.plist"

    print_step "Installing hausputz-server"
    hausputz_go_install hausputz-server || { print_warning "hausputz-server build failed"; return 0; }
    mkdir -p "$state" "$cfg"

    if ! security find-generic-password -s hausputz-jev >/dev/null 2>&1; then
        local key
        if key=$(op read "op://terminal access/hausputz jev api key/credential" 2>/dev/null) && [[ -n "$key" ]]; then
            if security add-generic-password -U -s hausputz-jev -a hausputz -w "$key" >/dev/null 2>&1; then
                print_success "Jev key stored in Keychain"
            else
                print_info "Keychain not writable here (SSH session): the service reads the Jev key with op at run time"
            fi
            unset key
        else
            print_warning "Jev key not readable from 1Password: every item waits"
        fi
    fi

    # Token hashes only; the tokens themselves stay in 1Password and Keychains.
    local m t first=1
    {
        printf '{'
        for m in cc1 caseys-air; do
            if t=$(op read "$HAUSPUTZ_OP_ITEM/$m" 2>/dev/null) && [[ -n "$t" ]]; then
                [[ $first == 1 ]] || printf ','
                printf '"%s":"%s"' "$m" "$(printf %s "$t" | shasum -a 256 | cut -d' ' -f1)"
                first=0
            fi
        done
        printf '}\n'
    } > "$tokens.tmp" && mv "$tokens.tmp" "$tokens"
    unset t
    chmod 600 "$tokens"

    cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>de.cdit.hausputz-server</string>
  <key>ProgramArguments</key><array><string>/bin/zsh</string><string>-c</string>
    <string>source ~/.env.sh 2&gt;/dev/null; PATH=/opt/homebrew/bin:\$PATH exec "$bin" -listen 127.0.0.1:8787 -rules "$HAUSPUTZ_REPO/rules/seed.json" -login "$HAUSPUTZ_UI_LOGIN"</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$state/server.log</string>
  <key>StandardErrorPath</key><string>$state/server.log</string>
</dict></plist>
PLIST
    hausputz_load_agent de.cdit.hausputz-server "$plist" && print_success "hausputz-server running on 127.0.0.1:8787"

    if command_exists tailscale && ! tailscale serve status 2>/dev/null | grep -q 8787; then
        tailscale serve --bg 8787 >/dev/null && print_success "tailnet: $HAUSPUTZ_SERVER_URL"
    fi
}
