<#
.SYNOPSIS
    Bootstrap a new Windows dev machine using WinGet DSC.

.DESCRIPTION
    Run this script from a plain PowerShell prompt.
    It is the only step you need to run manually on a fresh machine.

    Usage (from the repo root):
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\windows\bootstrap.ps1

    The script will:
      1. Verify winget is available (1.6+ required for DSC support).
      2. Run the declarative configuration in windows\setup.winget, which
         installs all packages, enables Windows features, and symlinks configs.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section([string]$Title) {
    Write-Host "`n== $Title ==" -ForegroundColor Cyan
}

# ---------------------------------------------------------------------------
# 1. Verify winget is available and supports DSC (1.6+)
# ---------------------------------------------------------------------------
Write-Section "Checking prerequisites"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error @"
winget is not available on this machine.
Install the 'App Installer' package from the Microsoft Store, or download it from:
  https://github.com/microsoft/winget-cli/releases
Then re-run this script.
"@
    exit 1
}

$wingetVersion = (winget --version).TrimStart('v')
$minVersion    = [Version]'1.6.0'
if ([Version]$wingetVersion -lt $minVersion) {
    Write-Error "winget $wingetVersion is too old. Version 1.6+ is required for DSC support. Update via the Microsoft Store."
    exit 1
}

Write-Host "winget $wingetVersion found." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Apply the WinGet DSC configuration
# ---------------------------------------------------------------------------
Write-Section "Applying WinGet DSC configuration"

$configFile = Join-Path $PSScriptRoot 'setup.winget'
Write-Host "Configuration file: $configFile"
Write-Host ""

winget configure --file $configFile --accept-configuration-agreements

if ($LASTEXITCODE -ne 0) {
    Write-Error "winget configure failed (exit $LASTEXITCODE). Review the output above."
    exit $LASTEXITCODE
}

Write-Section "Done"
Write-Host "Bootstrap complete. Open a new WezTerm window to verify everything works." -ForegroundColor Green
