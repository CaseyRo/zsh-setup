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
- Theme follows HA `input_select.house_mode`: day → moss light
  (cobalt-cdit-day); evening/night → Cobalt dark (cobalt-cdit-evening);
  morning/guest/away → macOS Auto appearance
  (~/dev/keychron-q11/bin/herdr-daylight, every 5 min and on wake). It also
  sets Claude Code's theme (light-ansi / dark-ansi).
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
- Terminal font: MesloLGS Nerd Font Mono (settings.json).

## Brand Commitments

- CDiT / casey.berlin design system (claude.ai artifact AHV1UBMCAmRjNSdmGp22mv):
  Schwarzwald Moss, Weathered Ochre (≤5%, earns it), Warm Workshop Cream,
  Pine Ink, Soft Moss; no pure #fff/#000; flat, no shadows; the
  horizon-and-point mark.
- Cobalt2, as in Casey's Warp setup, is the other half of the mashup
  (navy ground, yellow, the Warp ANSI set).
- Casey's ask for daylight: "CDiT green translucent", not white paper.
- Anti-goals (Casey, 2026-11-04): a generic dev-tool look; busy chrome
  competing with terminal text; brand overload where moss/ochre/serif make
  the tool stop feeling like a tool.

## Product Principles

1. Terminal text first: chrome serves it and never outshouts it.
2. Agent state is the loudest signal on screen, and only when it needs Casey.
3. The brand shows in precise details (ground, one accent, the mark), not
   coverage.
4. The look follows the house: moss by day, Cobalt in the evening.

## Accessibility & Inclusion

WCAG AA contrast in every theme (4.5:1 text, 3:1 icons and focus), verified
against Herdr's resolved colours, not only the theme files.
