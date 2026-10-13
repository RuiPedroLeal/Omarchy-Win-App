# Omarchy Win-App

> **_NOTE:_**  INITIAL VERSION, HIGHLY EXPERIMENTAL and BUGGY!


Open programs from the [Omarchy](https://omarchy.org) Windows VM as normal windows in Hyprland, using RDP RemoteApp, instead of the full Windows desktop.

```bash
win-app 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE' Word
```

Launcher entries for **Word**, **Excel**, **PowerPoint** and **Notepad** are included, so they show up in Super+Space.

## How it works

Windows client editions allow only one RDP connection per session. If every app opened its own `xfreerdp3` connection, each new app would take the session from the others and make their windows disconnect and refresh. So win-app keeps **one connection for all apps**:

1. The first `win-app` call opens a RemoteApp connection whose only program is a hidden PowerShell helper, `win-app-agent.ps1`, run through `conhost --headless`.
2. Every `win-app` call writes a request file to `~/.local/state/win-app/queue/`.
3. The helper reads that folder through the redirected home drive (`\\tsclient\home`) every 2 seconds and starts each requested program inside the existing session.
4. Once all the apps it started have closed, the helper exits and the connection closes. The VM keeps running.

If the helper has died, `win-app` notices that its request wasn't picked up within 6 seconds, then restarts the connection and opens the app anyway.

If the VM isn't running, `win-app` starts it with one polkit prompt and leaves it running afterwards.

## Requirements

- Omarchy with the Windows VM installed (`omarchy-windows-vm install`), which also provides `xfreerdp3`, `nc` and `jq`
- Windows Pro or Enterprise in the VM (Home can't host RDP)

## Install

```bash
./install.sh
```

This installs:

| File | Location |
| --- | --- |
| `bin/win-app` | `~/.local/bin/win-app` |
| `windows/win-app-agent.ps1` | `~/.local/share/win-app/` |
| `windows/setup-remoteapp.ps1` | `~/.local/share/win-app/` |
| `applications/*.desktop.in` | `~/.local/share/applications/` |
| `windows/setup-remoteapp.ps1` (copy for the VM) | `~/Windows/` |

Re-run `./install.sh` to update. Run `./uninstall.sh` to remove everything. The VM isn't touched.

### One-time Windows setup

RemoteApp has to be allowed inside Windows. Open the full desktop (`omarchy-windows-vm launch -k`) and start an **Administrator** PowerShell. The Linux home folder isn't shared in that session, so `install.sh` already copied `setup-remoteapp.ps1` into `~/Windows`, which Windows sees as the shared folder `\\host.lan\Data`. Run:

```powershell
powershell -ExecutionPolicy Bypass -File \\host.lan\Data\setup-remoteapp.ps1
```

It:
- lets RemoteApp launch any program
- turns off the idle and disconnected session time limits
- turns off sleep and hibernation

Then restart Windows and **sign out** of the desktop session (Start → Sign out). An open desktop session clashes with RemoteApp.

## Adding apps

Copy one of the `applications/*.desktop.in` templates, change `Name`, the program path and the name argument, then re-run `./install.sh`:

```ini
Exec=uwsm app -- @WIN_APP@ "C:\\\\Program Files\\\\App\\\\app.exe" App
```

Backslashes are doubled twice: once for the desktop-entry format and once for the shell quoting. The Office entries assume the default 64-bit Microsoft 365 install folder, `C:\Program Files\Microsoft Office\root\Office16\`.

## Notes and limitations

- Store apps (such as the new Notepad on Windows 11) may not open reliably as a RemoteApp. Classic Win32 programs work best.
- Opening the full desktop (`omarchy-windows-vm launch`) while RemoteApp windows are open takes the session from them, and the other way round.
- win-app calls the internal `__priv up_wait` action of `omarchy-windows-vm`, because Omarchy has no public "start without connecting" command. A future Omarchy update could break this.
- All RemoteApp windows share the Hyprland window class `win-app`, which you can use in window rules.

## Uninstall

```bash
./uninstall.sh
```
