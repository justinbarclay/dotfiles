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

# Trigger at logon for the current user
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Use the full DOMAIN\User identity; $env:USERNAME resolves to SYSTEM when elevated.
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force

Write-Host "Successfully registered scheduled task: $TaskName"
Write-Host "This task will run silently every time you log in to check for configuration drift."
