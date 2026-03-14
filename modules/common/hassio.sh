# Home Assistant CLI (hassio) — inject token from 1Password at runtime
hassio() {
  HASSIO_TOKEN="$(op read 'op://Private/zztswjg7doxnjupfp4wgrk24kq/credential')" command hassio "$@"
}
