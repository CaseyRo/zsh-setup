# Lean, scripted Mac desktop (Omarchy-flavoured macOS)

Status: open
Started: 2026-10-17

## Destination

A fresh Mac reaches Casey's desktop from one repo command: near-zero UI animation, no Dock to manage,
a minimal top bar for jumping between spaces and apps, windows placed freely, layouts only on demand.

## Why now

KiwiDesk trial made the wanted shape concrete (top bar + space jumping) and showed what's unwanted (fixed
layouts). Omarchy showed what an opinionated, reproducible desktop looks like. Weak spot: "AI can script it"
was already true a year ago, so that part is not a trigger.

## Open questions

1. Is there a stack that gives space browser + app jumper + free placement + on-demand layouts **without
   SIP disabled** and without a tiler fighting free dragging? Trial running: AeroSpace, all windows
   floating, on the MacBook Air, 2026-10-17 → 2026-10-24. Casey judges. (0.21.3-Beta, alt/alt-shift;
   AeroSpace can't place floating windows in halves or maximize them, so Raycast still handles placement.)
2. Do the browser-safe animation keys (window open/resize, Quick Look, Dock, Finder) actually change
   anything visible on macOS 26? They write cleanly, but the effect is unverified. Check over VNC on cc1.

## Resolved

- Can animation be cut without Reduce Motion? Partly. Reduce Motion is the only switch for the Spaces
  slide, and it leaks to browsers (Safari and Chrome on Mac both follow it). AeroSpace doesn't use native
  Spaces, so the working Mac doesn't need Reduce Motion. Reduce Motion can be set from a script on 26.5
  (cc1: `defaults write` → the system API reports it on).
- One bar or two? One. Bartender keeps the menu bar and the notch; AeroSpace's workspace indicator is
  one more menu bar item that Bartender manages.
- Does desktop config belong in this repo? Yes, so the rename to `machine-setup` is in.
- Hosts differ: cc1 is VNC-only and gets everything (Reduce Motion, Reduce Transparency, no smooth scroll).
  The MacBook Air is the working machine and only gets the browser-safe keys.

## Fog

- What OnyX actually did for you: tweaks you'd keep, or maintenance (caches, rebuilds) nobody needs.
- Whether the Air on a big external screen wants different settings from the Air on its own.

## Out of scope

- Leaving macOS for real (actual Omarchy / Hyprland on Linux). The compositor stays Apple's; this hides it.
- Changing browser animation. It's a fixed constraint, not a setting to tune.

## Verdict
