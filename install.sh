#!/bin/bash
# Install win-app, its Windows-side agent and the app launcher entries for the
# current user. Re-run to update.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/win-app"
APPS_DIR="$HOME/.local/share/applications"

if ! command -v omarchy-windows-vm >/dev/null; then
  echo "omarchy-windows-vm not found. This needs Omarchy with the Windows VM installed." >&2
  exit 1
fi
for cmd in xfreerdp3 nc jq; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd (run: omarchy-windows-vm install)" >&2; exit 1; }
done

install -Dm755 "$SRC/bin/win-app" "$BIN_DIR/win-app"
install -Dm644 "$SRC/windows/win-app-agent.ps1" "$SHARE_DIR/win-app-agent.ps1"
install -Dm644 "$SRC/windows/setup-remoteapp.ps1" "$SHARE_DIR/setup-remoteapp.ps1"

mkdir -p "$APPS_DIR"
for template in "$SRC"/applications/*.desktop.in; do
  target="$APPS_DIR/$(basename "$template" .in)"
  sed "s#@WIN_APP@#$BIN_DIR/win-app#" "$template" >"$target"
  chmod 644 "$target"
done
update-desktop-database "$APPS_DIR" 2>/dev/null || true

# Earlier versions kept the agent in ~/.config/windows.
rm -f "$HOME/.config/windows/win-app-agent.ps1"

# Also drop the Windows setup script in the VM's shared folder for easy access.
if [[ -d $HOME/Windows ]]; then
  install -m644 "$SRC/windows/setup-remoteapp.ps1" "$HOME/Windows/setup-remoteapp.ps1"
fi

echo "Installed win-app."
echo
echo "One-time Windows setup (if not done yet): open the VM desktop, then from an"
echo "Administrator PowerShell run setup-remoteapp.ps1 from the shared folder:"
echo '  powershell -ExecutionPolicy Bypass -File \\host.lan\Data\setup-remoteapp.ps1'
echo "Restart Windows and sign out of the desktop before using win-app."
