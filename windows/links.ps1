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

# Creates/repairs every symlink in the manifest. Requires Developer Mode (unprivileged mklink).
function Install-DotfilesLinks {
    param(
        [string]$DotfilesRoot = (Join-Path $env:USERPROFILE 'dotfiles')
    )
    foreach ($link in (Get-DotfilesLinks -DotfilesRoot $DotfilesRoot)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $link.Dest -Parent) | Out-Null

        if (Test-Path $link.Dest) {
            $item = Get-Item $link.Dest -Force
            if (-not $item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                Remove-Item $link.Dest -Force
            } elseif ($item.Target -eq $link.Src) {
                continue
            } else {
                Remove-Item $link.Dest -Force
            }
        }

        & cmd.exe /c "mklink `"$($link.Dest)`" `"$($link.Src)`"" | Out-Null
    }
}
