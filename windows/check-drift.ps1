$configFile = Join-Path $HOME "dotfiles\windows\setup.winget"
$logFile = Join-Path $env:TEMP "winget-drift.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Run the test silently
# Exit Code 0 = In Sync
# Exit Code 0x8A15C105 (-1978285819) = Drift Detected
$process = Start-Process -FilePath "winget.exe" `
    -ArgumentList "configure test -f `"$configFile`" --accept-configuration-agreements --disable-interactivity" `
    -Wait -PassThru -NoNewWindow

if ($process.ExitCode -ne 0) {
    $msg = "[$timestamp] DRIFT DETECTED: System state does not match configuration."
    Write-Warning $msg
    # Log the drift
    $msg | Out-File -FilePath $logFile -Append
} else {
    "[$timestamp] SUCCESS: System is in sync." | Out-File -FilePath $logFile -Append
}
