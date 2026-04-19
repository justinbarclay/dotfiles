# install-drift-task.ps1
# Requires elevation (run with sudo)

$TaskName = "DotfilesDriftCheck"
$ScriptPath = Join-Path $HOME "dotfiles\windows\check-drift.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Could not find check-drift.ps1 at $ScriptPath"
    exit 1
}

$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Trigger at logon for the current user
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Run with highest privileges (needed to check Registry/System features)
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

Write-Host "Successfully registered scheduled task: $TaskName"
Write-Host "This task will run silently every time you log in to check for configuration drift."
