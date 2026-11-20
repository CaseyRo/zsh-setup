#!/bin/bash
# ============================================================================
# Herdr: desktop app + herdr-core (`hc`)
# ============================================================================
# Replaces the Herdr TUI (brew `herdr`, ~/.config/herdr): the two don't share
# agents, and the cockpit lives in Herdr desktop now. A Mac dev machine gets
# the app, whose installer brings herdr-core with it; every other host (cc1,
# servers) gets herdr-core alone, so the desktop can reach it as a machine.
# Both self-update after the first install, so a re-run only checks presence.
# ============================================================================

install_herdr() {
    print_section "Herdr"
    local releases="https://releases.herdr.dev"

    if [[ "$IS_MAC_DEV_MACHINE" == true ]]; then
        if [[ -d "$HOME/Applications/Herdr.app" || -d /Applications/Herdr.app ]]; then
            print_skip "Herdr desktop (already installed; it updates itself)"
            track_skipped "Herdr desktop"
            return 0
        fi
        print_step "Installing Herdr desktop + herdr-core"
        if curl -fsSL "$releases/app/install.sh" | sh; then
            track_installed "Herdr desktop"
        else
            print_error "Herdr desktop install failed"
            track_failed "Herdr desktop"
        fi
        return 0
    fi

    # A working core, not just a file: a dead symlink must not count as installed.
    if "$HOME/.local/bin/herdr-core" --version >/dev/null 2>&1 || herdr-core --version >/dev/null 2>&1; then
        print_skip "herdr-core (already installed; it updates itself)"
        track_skipped "herdr-core"
        return 0
    fi
    print_step "Installing herdr-core (hc)"
    if curl -fsSL "$releases/core/install.sh" | sh; then
        track_installed "herdr-core"
    else
        print_error "herdr-core install failed"
        track_failed "herdr-core"
    fi
    return 0
}

# ============================================================================
# Herdr desktop (herdr-app) cockpit
# ============================================================================
# The cockpit layout, its two mods, the moss day / Cobalt evening themes and
# keys.json, copied into ~/.config/herdr-app when missing or changed: the repo
# is the source of truth, as for the Warp themes. Copied, not symlinked, for
# the same write-then-rename reason as above. Herdr writes the rest of that
# folder itself. keychron-q11's bin/herdr-daylight switches the two themes.
# PRODUCT.md is the brief behind it and stays in the repo.
# ============================================================================

deploy_herdr_app_config() {
    local app_dir="$HOME/.config/herdr-app"
    local source_dir="$SCRIPT_DIR/configs/herdr-app"
    [[ -d "$source_dir" ]] || return 0

    # Herdr makes the folder on its first start; before that there is nothing to theme.
    if [[ ! -d "$app_dir" ]]; then
        print_skip "Herdr desktop config (open Herdr once, then re-run)"
        track_skipped "Herdr desktop config"
        return 0
    fi

    local src rel target
    while IFS= read -r -d '' src; do
        rel="${src#"$source_dir"/}"
        [[ "$rel" == PRODUCT.md ]] && continue
        target="$app_dir/$rel"
        if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
            continue
        fi
        mkdir -p "$(dirname "$target")"
        cp "$src" "$target"
        print_success "Herdr desktop: $rel"
        track_installed "Herdr desktop $rel"
    done < <(find "$source_dir" -type f -print0)
}

# ============================================================================
# Herdr desktop: the settings this cockpit owns
# ============================================================================
# settings.json is Herdr's, not ours: the app rewrites it whenever Casey changes
# zoom, fonts or alerts in Settings. So this patches the three keys the cockpit
# decides and leaves the rest of the file alone — copying the whole file would
# silently revert his own clicks on the next run.
#   sounds.enabled false  Herdr plays an MP3 every time an agent finishes or
#                         blocks; with a dozen panes that is all day (Casey,
#                         20 Nov 2026: "stop the annoying bits of sounds").
#   font                  Herdr ships plain JetBrains Mono, which has no Nerd
#                         Font glyphs, so Starship's prompt renders as tofu.
#                         MesloLGS is the house terminal font (PRODUCT.md).
#   font_ligatures false  Prompt and diff alignment over ligatures.
# ============================================================================

patch_herdr_app_settings() {
    local settings="$HOME/.config/herdr-app/settings.json"
    [[ -f "$settings" ]] || return 0
    command_exists python3 || {
        print_skip "Herdr desktop settings (no python3)"
        return 0
    }

    local out
    if out=$(HERDR_SETTINGS="$settings" python3 - <<'PY'
import json, os, pathlib, sys

want = {
    "sounds": {"enabled": False},
    "font": "MesloLGS Nerd Font Mono",
    "font_ligatures": False,
}
path = pathlib.Path(os.environ["HERDR_SETTINGS"])
try:
    cur = json.loads(path.read_text() or "{}")
except (OSError, ValueError) as err:
    print(f"unreadable: {err}", file=sys.stderr)
    raise SystemExit(2)
if not isinstance(cur, dict):
    print("not an object", file=sys.stderr)
    raise SystemExit(2)

changed = []
for key, value in want.items():
    if isinstance(value, dict):
        have = cur.get(key) if isinstance(cur.get(key), dict) else {}
        if any(have.get(k) != v for k, v in value.items()):
            cur[key] = {**have, **value}
            changed.append(key)
    elif cur.get(key) != value:
        cur[key] = value
        changed.append(key)

if changed:
    # Write-then-rename: Herdr reads this file live.
    tmp = path.with_suffix(".json.new")
    tmp.write_text(json.dumps(cur, indent=2) + "\n")
    tmp.replace(path)
print(",".join(changed))
PY
    ); then
        if [[ -n "$out" ]]; then
            print_success "Herdr desktop settings: $out"
            track_installed "Herdr desktop settings"
        else
            print_skip "Herdr desktop settings (already set)"
            track_skipped "Herdr desktop settings"
        fi
    else
        print_error "Herdr desktop settings patch failed"
        track_failed "Herdr desktop settings"
    fi
    return 0
}
