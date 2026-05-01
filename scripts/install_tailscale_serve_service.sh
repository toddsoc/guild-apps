#!/usr/bin/env bash
# Copyright (c) 2026 The Smart Guild LLC
# Maintainer: Todd O'Connell <toddsoc@linux.com>
# SPDX-License-Identifier: MIT

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="${SERVICE_NAME:-tailscale-serve.service}"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
SUDO_BIN="${SUDO_BIN:-sudo}"

if ! command -v "$SUDO_BIN" >/dev/null 2>&1; then
    echo "sudo is required to install ${SERVICE_NAME}" >&2
    exit 1
fi

TMP_UNIT="$(mktemp)"
trap 'rm -f "$TMP_UNIT"' EXIT

cat >"$TMP_UNIT" <<EOF
[Unit]
Description=Publish shared nginx through Tailscale Serve
After=network-online.target tailscaled.service
Wants=network-online.target
Requires=tailscaled.service

[Service]
Type=oneshot
WorkingDirectory=${ROOT_DIR}
ExecStart=${ROOT_DIR}/scripts/tailscale_serve.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

"$SUDO_BIN" install -m 0644 "$TMP_UNIT" "$SERVICE_PATH"
"$SUDO_BIN" systemctl daemon-reload
"$SUDO_BIN" systemctl enable --now "$SERVICE_NAME"

echo "Installed and enabled ${SERVICE_NAME}"
"$SUDO_BIN" systemctl status --no-pager "$SERVICE_NAME"
