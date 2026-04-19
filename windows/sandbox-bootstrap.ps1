<#
.SYNOPSIS
    Bootstrap script for Windows Sandbox testing.

.DESCRIPTION
    This script is called automatically by test-sandbox.wsb.
    It installs WinGet (which is missing in Sandbox) and then runs the main bootstrap.
#>

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Title) {
    Write-Host "`n>> $Title" -ForegroundColor Cyan
}

# 1. Install WinGet
Write-Step "Installing WinGet for Sandbox..."
$progressPreference = 'silentlyContinue'
try {
    # This official shortcut downloads the latest WinGet bundle and its dependencies (VCLibs)
    Invoke-Expression (Invoke-WebRequest -Uri "https://aka.ms/installwinget" -UseBasicParsing).Content
} catch {
    Write-Error "Failed to install WinGet. Sandbox may have networking issues or the aka.ms link changed."
    exit 1
}

# 2. Re-launch main bootstrap
Write-Step "WinGet installed. Starting main bootstrap..."
$dotfilesDir = "C:\Users\WDAGUtilityAccount\Desktop\dotfiles"

if (Test-Path $dotfilesDir) {
    Set-Location $dotfilesDir
    .\windows\bootstrap.ps1
} else {
    Write-Error "Could not find dotfiles directory at $dotfilesDir. Check your .wsb configuration."
    exit 1
}
