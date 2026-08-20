# zsh-setup

Cross-platform zsh dotfiles and machine bootstrap for macOS, Ubuntu, and
Raspberry Pi. The repository is the deliverable: `~/.zshrc` is a symlink into
this checkout, and `install.sh` is the single provisioning entry point.

## Shortest path

```bash
git clone https://github.com/CaseyRo/zsh-setup.git ~/dev/zsh-setup
cd ~/dev/zsh-setup
./install.sh            # full install, interactive
./install.sh -y         # answer yes to everything
./install.sh --light    # minimal server or virtual private server
./install.sh --dev      # macOS dev machine profile
bash scripts/doctor.sh  # health-check an existing install (alias: zsh-doctor)
```

Re-running is the normal case, not the recovery case. Every installer module
checks whether its target is already present and skips. See
[installer](installer.md).

## Where the knowledge lives

The code answers *what happens*. These pages answer *why it is shaped that
way*, which is the part you cannot recover by reading a script.

Four constraints account for most of the surprising code in this repository:

1. Shell startup time is a budget, and the loader is synchronous. One module in
   the wrong position cost roughly 700 milliseconds per shell. See
   [shell runtime](shell-runtime.md).
2. Ordering constraints are encoded in filenames and fail quietly. A module
   loaded too early usually still works, just slower or with a cache defeated.
   See [shell runtime](shell-runtime.md).
3. Installers run repeatedly against machines in unknown states, so idempotence
   is a contract rather than a nicety. Two failure shapes recur: a skip guard
   that checks whether something is present rather than whether it works, and a
   single module's failure ending the whole run under `set -e`. Both look like
   success from the outside. See [installer](installer.md).
4. Work detached to keep the prompt fast is still attached to the terminal it
   came from, and when it stops there is no error anywhere. The daily
   self-update spent twenty nine hours stopped, holding the lock that would
   have let a later shell retry, while the repository went on reporting itself
   up to date. See [shell runtime](shell-runtime.md).

## For agents working in this repo

Read the page covering the area you are about to touch before opening source
files. Each section carries a coverage tag:

- `[coverage: high]` covers the reasoning fully. You still read the code for
  exact syntax, never for intent.
- `[coverage: medium]` gives you the shape. Check the linked sources for detail.
- `[coverage: low]` means go straight to the listed files.

This wiki never restates behavior that the code already states. When a question
is "what does this do", the answer is in the script. When it is "why is it done
this way" or "what breaks if I change it", the answer is here.

## Map

- [quickstart](quickstart.md): this page. Entry point and map.
- [installer](installer.md): provisioning. Entry point and profiles, persisted
  state, platform detection, package lists, the package-manager preference
  ladder, runtime version management, config seeding, and the unattended
  re-provisioning path.
- [shell runtime](shell-runtime.md): what every interactive shell loads. Loader
  order, per-operating-system scoping, the `zz_` tail-init contract, the `#`
  opt-out convention, and the daily self-update.
- [quality gates](quality-gates.md): the two shellcheck scopes, pre-commit
  hooks, automatic versioning, and the continuous integration smoke test.
