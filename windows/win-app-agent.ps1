# Runs hidden inside the Windows VM as the single RemoteApp of a win-app connection.
# win-app (on Linux) drops request files into ~/.local/state/win-app/queue, which
# this agent reads through the redirected home drive and starts in this session,
# so every app shares one RDP connection instead of stealing the session.
# Exits once every app it started has closed, which ends the RDP connection.

$Queue = '\\tsclient\home\.local\state\win-app\queue'
$Session = (Get-Process -Id $PID).SessionId
$Launched = @{}
$IdleSince = Get-Date

# A reconnect reuses the Windows session, so an older agent may still be alive in
# it; two agents would race for requests.
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' AND CommandLine LIKE '%win-app-agent%'" |
    Where-Object { $_.ProcessId -ne $PID -and $_.SessionId -eq $Session } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

function Test-AppsAlive {
    foreach ($name in $Launched.Keys) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object SessionId -eq $Session) {
            return $true
        }
    }
    return $false
}

while ($true) {
    try {
        Get-ChildItem -Path $Queue -Filter '*.req' -ErrorAction Stop | Sort-Object Name | ForEach-Object {
            $lines = @(Get-Content -LiteralPath $_.FullName -Encoding UTF8)
            Remove-Item -LiteralPath $_.FullName -Force
            $program = $lines[0]
            $arguments = if ($lines.Count -gt 1) { $lines[1] } else { '' }
            if (-not $program) { return }
            try {
                if ($arguments) {
                    Start-Process -FilePath $program -ArgumentList $arguments
                } else {
                    Start-Process -FilePath $program
                }
                $Launched[[IO.Path]::GetFileNameWithoutExtension($program)] = $true
            } catch {
                Add-Type -AssemblyName PresentationFramework
                [System.Windows.MessageBox]::Show("win-app could not start:`n$program`n`n$_") | Out-Null
            }
        }
    } catch {
        # Redirected drive briefly unavailable (e.g. during auto-reconnect); retry.
    }

    if (Test-AppsAlive) {
        $IdleSince = Get-Date
    } elseif (((Get-Date) - $IdleSince).TotalSeconds -gt $(if ($Launched.Count) { 10 } else { 60 })) {
        exit
    }

    Start-Sleep -Seconds 2
}
