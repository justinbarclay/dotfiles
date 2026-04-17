<#
.SYNOPSIS
    Pre-bootstrap for a new Windows machine.
    Installs Nushell via winget, then hands off to bootstrap.nu.

.DESCRIPTION
    Run this script from a plain PowerShell prompt (no Nushell required).
    It is the only step you need to run manually on a fresh machine.

    Usage (from the repo root):
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\windows\bootstrap.ps1

    The script will:
      1. Verify winget is available.
      2. Install Nushell if it is not already present.
      3. Invoke windows\bootstrap.nu with the freshly installed nu.exe.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Section([string]$Title) {
    Write-Host "`n== $Title ==" -ForegroundColor Cyan
}

function Find-Nu {
    # 1. Already on PATH
    $onPath = Get-Command nu -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    # 2. Common winget install location for the current user
    $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Nushell.Nushell*\nu.exe'
    $found = Get-Item $candidate -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($found) { return $found.FullName }

    # 3. Scoop shim (in case the user ran scoop install nushell before this script)
    $scoopShim = Join-Path $env:USERPROFILE 'scoop\shims\nu.exe'
    if (Test-Path $scoopShim) { return $scoopShim }

    return $null
}

# ---------------------------------------------------------------------------
# 1. Verify winget is available
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

Write-Host "winget found." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Install Nushell (if missing)
# ---------------------------------------------------------------------------
Write-Section "Nushell"

$nuExe = Find-Nu
if ($nuExe) {
    Write-Host "Nushell already installed at: $nuExe" -ForegroundColor Green
} else {
    Write-Host "Installing Nushell via winget..."
    winget install --id Nushell.Nushell --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Error "winget install failed (exit $LASTEXITCODE). Check the output above."
        exit 1
    }

    # Refresh PATH in this session so nu.exe is findable without reopening the shell
    $machinePath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH    = "$userPath;$machinePath"

    $nuExe = Find-Nu
    if (-not $nuExe) {
        Write-Error @"
Nushell was installed but nu.exe could not be located automatically.
Open a new PowerShell window (so PATH is refreshed) and run:
  nu windows\bootstrap.nu
"@
        exit 1
    }
    Write-Host "Nushell installed at: $nuExe" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 3. Hand off to bootstrap.nu
# ---------------------------------------------------------------------------
Write-Section "Handing off to bootstrap.nu"

$repoRoot     = Split-Path -Parent $PSScriptRoot
$bootstrapNu  = Join-Path $PSScriptRoot 'bootstrap.nu'

Write-Host "Running: $nuExe $bootstrapNu"
& $nuExe $bootstrapNu

exit $LASTEXITCODE
