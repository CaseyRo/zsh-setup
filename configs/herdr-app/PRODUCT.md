# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

<!-- Not a web or mobile product: a macOS desktop cockpit made of Herdr desktop
     (GPUI app, layouts/mods/themes in ~/.config/herdr-app), Claude Code TUIs,
     zsh + Starship, and a Keychron Q11 with Hammerspoon. Recorded as `adaptive`
     only because the schema has no `desktop`; no iOS/Android work applies. -->

## Users

Casey Romkes, solo: CDiT's one-person workshop. All day in this window,
running several Claude Code agents at once across local spaces and the cc1
server, for client engagements and own projects.

## Product Purpose

The cockpit for supervising coding agents. The main job in a typical hour is
supervision: see at a glance which agent is working, blocked or done, jump to
the one that needs a person, answer, and move on. Success is never hunting
for the agent that's waiting, and the terminal text staying the most readable
thing on screen.

## Positioning

A personal instrument, not a product: Herdr's spaces/tabs/agents model,
driven from a Keychron macro column and knobs, its look following the house
(Home Assistant house mode) through day, dusk and night.

## Operating Context

- Herdr desktop: spaces (local "~", cc1 "dev"), tabs, panes; sidebar with
  Spaces and Agents lists; agent states working / blocked / done / idle.
- Keys: Cmd+1–9 spaces, Ctrl+1–9 tabs, Cmd+B sidebar, Cmd+Opt+arrows panes.
- Keychron: M1–M5 jump to spaces 1–5; left knob cycles spaces, press zooms
  the pane (router: ~/dev/keychron-q11/hammerspoon/init.lua).
- Theme: the cockpit layout pins `cobalt-yorizon` (Casey, 20 Nov 2026: "a
  cobalt theme with a bit of yorizon flavor"). The older moss/Cobalt pair
  (cobalt-cdit-day, cobalt-cdit-evening) stays in `themes/` for the hosts
  that run the house-mode switcher — HA `input_select.house_mode` → day:
  moss light, evening/night: Cobalt dark, morning/guest/away: macOS Auto
  (`~/dev/keychron-q11/bin/herdr-daylight`, every 5 min and on wake; absent
  on this Mac). That switcher also sets Claude Code's theme.
- Herdr does not answer OSC 11, so terminal programs cannot detect the
  background themselves.
- Copy-on-select via Hammerspoon. Long sessions, daylight to late night.

## Capabilities and Constraints

- Herdr look is set by themes (`themes/*.json`: background, foreground,
  selection, cursor, 16 ANSI, panel colour overrides) and layouts. Shipped
  layouts and mods must be cloned before structural edits. No window
  transparency to the desktop; no HTML/CSS; mods are GPUI JavaScript.
- Claude Code draws its own UI; only its theme choice is controllable.
- Prompt: Starship from the shared zsh-setup repo (all hosts), now on an
  ANSI `terminal` palette.
- Terminal font: MesloLGS Nerd Font Mono (settings.json). Herdr's own default
  is plain JetBrains Mono, which has no Nerd Font glyphs, so Starship's prompt
  renders as tofu until this is set.
- Silent by default (Casey, 20 Nov 2026). `settings.json` → `sounds.enabled:
  false` stops the done/blocked MP3s; the layout root's `toast: "quiet"` stops
  every in-app notification; Claude Code's `preferredNotifChannel` is
  `notifications_disabled` in `~/.claude.json`, because herdr-core reports
  `TERM_PROGRAM=ghostty` and Claude Code would otherwise post a desktop
  notification per permission and idle prompt. The sidebar is the only place
  agent state is announced. `install/herdr.sh` (`patch_herdr_app_settings`)
  owns the first, the layout owns the second; the Claude Code one lives in
  Claude's own global config, so a new host sets it once in `/config` →
  Notifications.

## Brand Commitments

- CDiT / casey.berlin design system (claude.ai artifact AHV1UBMCAmRjNSdmGp22mv):
  Schwarzwald Moss, Weathered Ochre (≤5%, earns it), Warm Workshop Cream,
  Pine Ink, Soft Moss; no pure #fff/#000; flat, no shadows; the
  horizon-and-point mark.
- Cobalt2, as in Casey's Warp setup, is the other half of the mashup
  (navy ground, yellow, the Warp ANSI set).
- Yorizon, where Casey spends his employed days: lime `#c8e600` on dark olive
  `#2a2b22`, warm off-white `#eceadf`. In `cobalt-yorizon` the lime is the
  accent and nothing else — focus, selection, the active space — and the olive
  is the ink on it. Lime never carries text on a light ground (Yorizon's rule).
- Casey's ask for daylight: "CDiT green translucent", not white paper.
- Anti-goals (Casey, 2026-11-04): a generic dev-tool look; busy chrome
  competing with terminal text; brand overload where moss/ochre/serif make
  the tool stop feeling like a tool.

## Product Principles

1. Terminal text first: chrome serves it and never outshouts it.
2. Agent state is the loudest signal on screen, and only when it needs Casey.
3. The brand shows in precise details (ground, one accent, the mark), not
   coverage.
4. The look follows the house: moss by day, Cobalt in the evening — where a
   host runs the switcher. Everywhere else, Cobalt.
5. Nothing beeps, chimes or pops. A pane that needs Casey goes ochre in the
   sidebar and waits; the cockpit never interrupts the room.

## Accessibility & Inclusion

WCAG AA contrast in every theme (4.5:1 text, 3:1 icons and focus), verified
against Herdr's resolved colours, not only the theme files.
