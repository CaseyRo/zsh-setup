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
