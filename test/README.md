# Install smoke tests

Dockerfiles here exercise `install.sh -y --light` against clean Linux images.
CI (`.github/workflows/install-smoke.yml`) runs them on every push/PR.

## What's covered

- Full `install.sh --light` path on Ubuntu 24.04 and Debian 12
- Idempotence: `install.sh` is run **twice** — the second run must succeed
- Shell startup after install: `zsh -i -c 'type cd'` (verifies modules load)

## Not covered

- **macOS** — needs a macOS runner; Homebrew path isn't exercised here.
- **`--dev` profile** — pulls GUI apps (Cursor, OrbStack); not installable in Docker.
- **Docker-in-Docker** — `install/apt.sh` already skips Docker repo setup when
  running inside a container, so no behavior to test.
- **ARM / Raspberry Pi** — optional matrix leg via `platform: linux/arm64`; add
  later if we want APT-on-ARM coverage (builds run ~5× slower under QEMU).

## Running locally

```bash
docker build -f test/Dockerfile.ubuntu -t zsh-setup-test:ubuntu .
docker build -f test/Dockerfile.debian -t zsh-setup-test:debian .
docker run --rm zsh-setup-test:ubuntu
```
