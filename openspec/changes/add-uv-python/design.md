## Context
The installer currently configures Node, Rust, and CLI tools but does not provision Python. uv provides fast, modern Python installs and environment management.

## Goals / Non-Goals
- Goals: Install uv, install the latest stable Python, and make it the default.
- Non-Goals: Managing project-specific virtual environments or dependency lockfiles.

## Decisions
- Decision: Use uv's official installer and keep a lightweight integration.
- Decision: Install Python via uv and set it as default during setup.

## Risks / Trade-offs
- Risk: uv installer requires network access.
  - Mitigation: Use existing network-enabled install flow and provide clear status output.

## Migration Plan
- None needed; this adds a new optional capability.

## Open Questions
- None.
