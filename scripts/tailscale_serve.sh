#!/usr/bin/env bash
# Copyright (c) 2026 The Smart Guild LLC
# Maintainer: Todd O'Connell <toddsoc@linux.com>
# SPDX-License-Identifier: MIT

set -euo pipefail

PORT="${PORT:-8080}"
TAILSCALE_BIN="${TAILSCALE_BIN:-tailscale}"
SUDO_BIN="${SUDO_BIN:-sudo}"
APP_PATH="${APP_PATH:-/RegEx/}"
RETRY_COUNT="${RETRY_COUNT:-30}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-2}"

if ! command -v "$TAILSCALE_BIN" >/dev/null 2>&1; then
    echo "tailscale CLI not found in PATH" >&2
    exit 1
fi

TS_CMD=("$TAILSCALE_BIN")

if [ "$(id -u)" -ne 0 ] && command -v "$SUDO_BIN" >/dev/null 2>&1 && "$SUDO_BIN" -n true >/dev/null 2>&1; then
    TS_CMD=("$SUDO_BIN" "$TAILSCALE_BIN")
fi

retry_ts() {
    local description="$1"
    shift

    local attempt
    for attempt in $(seq 1 "$RETRY_COUNT"); do
        if "$@"; then
            return 0
        fi

        if [ "$attempt" -lt "$RETRY_COUNT" ]; then
            echo "${description} failed; retrying in ${RETRY_DELAY_SECONDS}s (${attempt}/${RETRY_COUNT})..." >&2
            sleep "$RETRY_DELAY_SECONDS"
        fi
    done

    return 1
}

echo "Resetting existing Tailscale Serve configuration..."
retry_ts "Tailscale Serve reset" "${TS_CMD[@]}" serve reset

echo "Publishing HTTPS for localhost:${PORT}${APP_PATH} to your tailnet..."
retry_ts "Tailscale Serve publish" "${TS_CMD[@]}" serve --bg "$PORT"

echo
"$TAILSCALE_BIN" serve status
echo
echo "App path: ${APP_PATH}"
