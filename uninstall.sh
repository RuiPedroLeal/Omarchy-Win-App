#!/bin/bash
# Remove win-app and its launcher entries. The Windows VM itself is untouched.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$HOME/.local/share/applications"
STATE_DIR="$HOME/.local/state/win-app"

# Close the shared RDP connection if it is open.
pid=$(cat "$STATE_DIR/rdp.pid" 2>/dev/null || true)
if [[ -n $pid ]] && tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -q 'xfreerdp3.*win-app-agent'; then
  kill "$pid"
fi

for template in "$SRC"/applications/*.desktop.in; do
  rm -f "$APPS_DIR/$(basename "$template" .in)"
done
update-desktop-database "$APPS_DIR" 2>/dev/null || true

rm -f "$HOME/.local/bin/win-app"
rm -rf "$HOME/.local/share/win-app" "$STATE_DIR"
rm -f "$HOME/Windows/setup-remoteapp.ps1"

echo "Uninstalled win-app."
