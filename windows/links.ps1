<#
.SYNOPSIS
    Shared helpers for reading/creating/verifying the symlinks declared in windows\links.json.
    Dot-sourced by setup.winget (symlinks resource), check-drift.ps1, bootstrap.ps1, and ci.yml
    so the link list only has to be maintained in one place.
#>

function Get-DotfilesLinks {
    param(
        [string]$DotfilesRoot = (Join-Path $env:USERPROFILE 'dotfiles')
    )
    $manifest = Join-Path $DotfilesRoot 'windows\links.json'
    $cfg = Get-Content $manifest -Raw | ConvertFrom-Json
    $cfg.links | ForEach-Object {
        [PSCustomObject]@{
            Dest = $_.dest.Replace('$LOCALAPPDATA', $env:LOCALAPPDATA).Replace('$APPDATA', $env:APPDATA).Replace('$USERPROFILE', $env:USERPROFILE)
            Src  = Join-Path $DotfilesRoot $_.src
        }
    }
}

# Returns $true/$false, or (with -Detailed) an array of human-readable drift descriptions.
function Test-DotfilesLinks {
    param(
        [string]$DotfilesRoot = (Join-Path $env:USERPROFILE 'dotfiles'),
        [switch]$Detailed
    )
    $issues = @()
    foreach ($link in (Get-DotfilesLinks -DotfilesRoot $DotfilesRoot)) {
        if (-not (Test-Path $link.Dest -ErrorAction SilentlyContinue)) {
            $issues += "MISSING:      $($link.Dest)"
            continue
        }
        $item = Get-Item $link.Dest -Force
        if (-not $item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
            $issues += "NOT_SYMLINK:  $($link.Dest)"
            continue
        }
        if ($item.Target -ne $link.Src) {
            $issues += "WRONG_TARGET: $($link.Dest) -> $($item.Target) (expected: $($link.Src))"
        }
    }
    if ($Detailed) { return $issues }
    return ($issues.Count -eq 0)
}

# Creates/repairs a single symlink using native PowerShell New-Item.
function Install-Symlink {
    param(
        [Parameter(Mandatory=$true)][string]$LinkPath,
        [Parameter(Mandatory=$true)][string]$TargetPath
    )
    $parent = Split-Path $LinkPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $LinkPath) {
        Remove-Item $LinkPath -Force -Recurse
    }
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath -Force | Out-Null
}

# Creates/repairs every symlink in the manifest. Requires Developer Mode (unprivileged symlinks).
function Install-DotfilesLinks {
    param(
        [string]$DotfilesRoot = (Join-Path $env:USERPROFILE 'dotfiles')
    )
    foreach ($link in (Get-DotfilesLinks -DotfilesRoot $DotfilesRoot)) {
        Install-Symlink -LinkPath $link.Dest -TargetPath $link.Src
    }
}
