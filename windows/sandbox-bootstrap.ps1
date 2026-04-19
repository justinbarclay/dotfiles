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
$ProgressPreference = 'SilentlyContinue'
try {
    # Fetch the latest WinGet release from GitHub to avoid the fragile aka.ms redirect.
    $release  = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -UseBasicParsing
    $bundle   = $release.assets | Where-Object { $_.name -like '*.msixbundle'               } | Select-Object -First 1
    $vcLibs   = $release.assets | Where-Object { $_.name -like 'Microsoft.VCLibs*x64*.appx' } | Select-Object -First 1
    $uiXaml   = $release.assets | Where-Object { $_.name -like 'Microsoft.UI.Xaml*.appx'    } | Select-Object -First 1

    if (-not $bundle) { throw "Could not find .msixbundle asset in the latest WinGet release." }

    $bundlePath = Join-Path $env:TEMP $bundle.browser_download_url.Split('/')[-1]
    Invoke-WebRequest -Uri $bundle.browser_download_url -OutFile $bundlePath -UseBasicParsing

    if ($vcLibs)  {
        $vcPath = Join-Path $env:TEMP $vcLibs.browser_download_url.Split('/')[-1]
        Invoke-WebRequest -Uri $vcLibs.browser_download_url -OutFile $vcPath -UseBasicParsing
        Add-AppxPackage -Path $vcPath -ErrorAction SilentlyContinue
    }
    if ($uiXaml) {
        $uiPath = Join-Path $env:TEMP $uiXaml.browser_download_url.Split('/')[-1]
        Invoke-WebRequest -Uri $uiXaml.browser_download_url -OutFile $uiPath -UseBasicParsing
        Add-AppxPackage -Path $uiPath -ErrorAction SilentlyContinue
    }

    Add-AppxPackage -Path $bundlePath
} catch {
    Write-Error "Failed to install WinGet: $_"
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
