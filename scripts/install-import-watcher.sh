#!/usr/bin/env bash
# Install and enable the user systemd service for glasses import inbox watching.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ROOT/config/import-inbox.conf"
CONF_EXAMPLE="$ROOT/config/import-inbox.conf.example"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="reckless-rides-import-watcher.service"
SERVICE="$UNIT_DIR/$SERVICE_NAME"
LEGACY_SERVICE="$UNIT_DIR/debike-import-watcher.service"

if [[ ! -f "$CONF" ]]; then
  cp "$CONF_EXAMPLE" "$CONF"
  echo "Created $CONF"
fi

# shellcheck source=/dev/null
source "$CONF"
IMPORT_INBOX="${IMPORT_INBOX:-/home/ajlennon/LocalSend/rides-imports}"

mkdir -p "$IMPORT_INBOX" "$IMPORT_INBOX/done" "$IMPORT_INBOX/failed" "$UNIT_DIR"
chmod +x "$ROOT/scripts/process-import-inbox.sh" "$ROOT/scripts/watch-import-inbox.sh" "$ROOT/scripts/upload-pending-incidents.sh"

if [[ -f "$CONF" ]] && ! grep -q '^AUTO_YOUTUBE_UPLOAD=' "$CONF"; then
  printf '\n# After ingest, upload to YouTube as private\nAUTO_YOUTUBE_UPLOAD=true\n' >>"$CONF"
fi

# Retire legacy Dangerous eBikers / bike-imports watcher if present.
if systemctl --user is-active debike-import-watcher.service &>/dev/null; then
  systemctl --user disable --now debike-import-watcher.service
fi
rm -f "$LEGACY_SERVICE"

cat >"$SERVICE" <<EOF
[Unit]
Description=Reckless Rides UK glasses import inbox watcher
After=default.target

[Service]
Type=simple
WorkingDirectory=$ROOT
Environment=RRUK_IMPORT_CONF=$CONF
ExecStart=$ROOT/scripts/watch-import-inbox.sh
Restart=on-failure
RestartSec=15

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

echo ""
echo "Import watcher enabled."
echo "  Service: $SERVICE_NAME"
echo "  Inbox : $IMPORT_INBOX"
echo "  Done  : $IMPORT_INBOX/done"
echo "  Failed: $IMPORT_INBOX/failed"
echo ""
echo "Drop .MOV/.mp4 files into the inbox (LocalSend from glasses)."
echo "Pipeline: ingest -> done/ -> YouTube upload (private). Set public in Studio after review."
echo "Disable auto-upload: AUTO_YOUTUBE_UPLOAD=false in config/import-inbox.conf"
if [[ -d "/home/ajlennon/LocalSend/bike-imports" ]]; then
  echo ""
  echo "Note: legacy inbox bike-imports still exists — move any pending clips to rides-imports or set IMPORT_INBOX in config."
fi
echo ""
systemctl --user status "$SERVICE_NAME" --no-pager || true
