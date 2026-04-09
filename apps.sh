#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/compose/compose.yml"
PROJECT_NAME="oconnell"
OCONNELL_ENV_FILE="$ROOT_DIR/compose/.env.oconnell"

usage() {
  cat <<'USAGE'
Usage:
  ./apps.sh list
  ./apps.sh status [app|all]
  ./apps.sh start [app|all]
  ./apps.sh stop [app|all]
  ./apps.sh rebuild [app|all]

Apps:
  regex      Regex app behind nginx on localhost:8080/RegEx/
  oconnell   Coming soon site + Cloudflare tunnel
  all        All apps above
USAGE
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is required." >&2
    exit 1
  fi
}

compose_regex=(docker compose -f "$COMPOSE_FILE")
compose_oconnell=(docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE")

if [[ -f "$OCONNELL_ENV_FILE" ]]; then
  compose_regex+=(--env-file "$OCONNELL_ENV_FILE")
  compose_oconnell+=(--env-file "$OCONNELL_ENV_FILE")
else
  echo "Warning: $OCONNELL_ENV_FILE not found; oconnell cloudflared may fail to start." >&2
fi

list_apps() {
  cat <<'APPS'
regex
oconnell
APPS
}

status_regex() {
  "${compose_regex[@]}" ps regex-app nginx
}

status_oconnell() {
  "${compose_oconnell[@]}" --profile oconnell ps coming-soon cloudflared
}

start_regex() {
  "${compose_regex[@]}" up -d regex-app nginx
}

start_oconnell() {
  "${compose_oconnell[@]}" --profile oconnell up -d coming-soon cloudflared
}

stop_regex() {
  "${compose_regex[@]}" stop regex-app nginx
}

stop_oconnell() {
  "${compose_oconnell[@]}" --profile oconnell stop coming-soon cloudflared
}

rebuild_regex() {
  "${compose_regex[@]}" up -d --build regex-app nginx
}

rebuild_oconnell() {
  "${compose_oconnell[@]}" --profile oconnell up -d --build coming-soon cloudflared
}

run_for_target() {
  local action="$1"
  local target="$2"

  case "$target" in
    regex)
      "${action}_regex"
      ;;
    oconnell)
      "${action}_oconnell"
      ;;
    all)
      "${action}_regex"
      "${action}_oconnell"
      ;;
    *)
      echo "Error: unknown app '$target'. Use: regex, oconnell, or all." >&2
      exit 1
      ;;
  esac
}

main() {
  require_docker

  local cmd="${1:-}"
  local target="${2:-all}"

  case "$cmd" in
    list)
      list_apps
      ;;
    status|start|stop|rebuild)
      run_for_target "$cmd" "$target"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Error: unknown command '$cmd'." >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"
