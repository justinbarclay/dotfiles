# install-drift-task.ps1
# Requires elevation (run with sudo)

$TaskName = "DotfilesDriftCheck"
$ScriptPath = Join-Path $HOME "dotfiles\windows\check-drift.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Could not find check-drift.ps1 at $ScriptPath"
    exit 1
}

$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File `"$ScriptPath`""

# Two triggers: at logon (catches drift from a fresh sign-in) and daily at noon
# (catches drift on machines that stay logged in for weeks without a reboot).
$LogonTrigger = New-ScheduledTaskTrigger -AtLogOn
$DailyTrigger = New-ScheduledTaskTrigger -Daily -At 12:00pm
$Triggers = @($LogonTrigger, $DailyTrigger)

# Use the full DOMAIN\User identity; $env:USERNAME resolves to SYSTEM when elevated.
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Triggers -Principal $Principal -Force

Write-Host "Successfully registered scheduled task: $TaskName"
Write-Host "This task will run silently at every login and daily at noon to check for configuration drift."
