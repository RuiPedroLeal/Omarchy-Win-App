# One-time setup inside the Windows VM. install.sh copies this into ~/Windows, so
# from an elevated PowerShell in the VM desktop run:
#   powershell -ExecutionPolicy Bypass -File \\host.lan\Data\setup-remoteapp.ps1
# Restart Windows afterwards.

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

function Set-Dword($Path, $Name, $Value) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

$TsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'

# Allow RemoteApp to launch any program, not only an allow-list.
Set-Dword 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList' 'fDisabledAllowList' 1
Set-Dword $TsPolicy 'fAllowUnlistedRemotePrograms' 1

# Never end idle or disconnected sessions (0 = no limit).
Set-Dword $TsPolicy 'MaxIdleTime' 0
Set-Dword $TsPolicy 'MaxDisconnectionTime' 0

# Keep the VM awake so RemoteApp windows don't drop.
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

Write-Host 'RemoteApp configured. Restart Windows, then sign out of any desktop session before using win-app.'
