# ============================================================================
# Common Functions
# ============================================================================
# Shared functions for all systems

# Docker log functions
dl() {
    docker logs "$1" --follow --tail 100
}

dlc() {
    local DIRNAME=$(basename "$PWD")
    docker logs "$DIRNAME" --follow --tail 100
}

dcdcurl() {
    local DIRNAME=$(basename "$PWD")
    docker compose down && docker compose pull && docker compose up -d && docker compose logs -f
}

# Git shortcuts
lgpush() {
    git add .
    git commit -a -m "$1"
    git push
}

# Docker compose converter
composerize() {
    docker run -it maaxgr/composerize:latest composerize "$@"
}

# Docker cleanup - safe prune (preserves volumes and tagged images)
dclean() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker not installed"
        return 1
    fi
    echo "Removing: stopped containers, unused networks, dangling images, build cache"
    echo "Preserving: volumes, tagged images"
    docker system prune -f
}

# Docker cleanup - aggressive (also removes unused images, but still preserves volumes)
dclean-all() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker not installed"
        return 1
    fi
    echo "Removing: stopped containers, unused networks, ALL unused images, build cache"
    echo "Preserving: volumes"
    docker system prune -af
}
