Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$configFile = Join-Path $HOME "dotfiles\windows\setup.winget"
$logDir     = Join-Path $env:LOCALAPPDATA "dotfiles"
$logFile    = Join-Path $logDir "winget-drift.log"
$timestamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$dotfiles   = Join-Path $env:USERPROFILE 'dotfiles'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Toast notification helper
# Uses WinRT directly — no external modules needed.
# AppId must be a registered Start menu entry; PowerShell's own GUID is always present.
# ---------------------------------------------------------------------------
function Send-DriftToast {
    param(
        [string]$Title,
        [string]$Body
    )
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]          | Out-Null

        $escaped = [System.Security.SecurityElement]::Escape($Body)
        $xml     = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml(@"
<toast activationType="protocol" launch="$logFile">
  <visual>
    <binding template="ToastGeneric">
      <text>$Title</text>
      <text>$escaped</text>
    </binding>
  </visual>
  <actions>
    <action content="View log" activationType="protocol" arguments="$logFile" />
  </actions>
</toast>
"@)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        # PowerShell's AUMID — always registered, no setup required.
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    } catch {
        # Non-fatal: notification failure should never mask the log entry.
        Write-Warning "Toast notification failed: $_"
    }
}

# ---------------------------------------------------------------------------
# 1. WinGet DSC drift check
# Exit Code 0 = In Sync, 0x8A15C105 (-1978285819) = Drift Detected
# Use direct invocation (not Start-Process) so stdout/stderr are captured.
# ---------------------------------------------------------------------------
$driftIssues = @()

$output = & winget.exe configure test -f "$configFile" --accept-configuration-agreements --disable-interactivity 2>&1

if ($LASTEXITCODE -ne 0) {
    $msg = "[$timestamp] DRIFT DETECTED (exit $LASTEXITCODE):`n$($output -join "`n")"
    Write-Warning $msg
    $msg | Out-File -FilePath $logFile -Append -Encoding utf8
    $driftIssues += "WinGet DSC resources are out of sync."
} else {
    "[$timestamp] SUCCESS: System is in sync." | Out-File -FilePath $logFile -Append -Encoding utf8
}

# ---------------------------------------------------------------------------
# 2. Symlink target validation
# Verifies each symlink exists AND points to the expected source file.
# winget configure test only checks presence (ReparsePoint attribute).
# ---------------------------------------------------------------------------
. (Join-Path $PSScriptRoot 'links.ps1')
$symlinkDrift = Test-DotfilesLinks -DotfilesRoot $dotfiles -Detailed

if ($symlinkDrift.Count -gt 0) {
    $msg = "[$timestamp] SYMLINK DRIFT DETECTED:`n$($symlinkDrift -join "`n")"
    Write-Warning $msg
    $msg | Out-File -FilePath $logFile -Append -Encoding utf8
    $driftIssues += "$($symlinkDrift.Count) symlink(s) broken or pointing to wrong targets."
}

# ---------------------------------------------------------------------------
# 3. Fire a single toast summarising all drift, if any was found.
# ---------------------------------------------------------------------------
if ($driftIssues.Count -gt 0) {
    Send-DriftToast -Title '⚠️ Dotfiles Drift Detected' -Body ($driftIssues -join ' | ')
}
