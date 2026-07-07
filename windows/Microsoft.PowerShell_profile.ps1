# Managed by dotfiles (windows/Microsoft.PowerShell_profile.ps1), symlinked to both the
# Windows PowerShell 5.1 and PowerShell 7 profile paths via windows/links.json.
# Nushell is the primary shell; this exists so elevated prompts, DSC script resources,
# and tools that shell out to powershell.exe/pwsh still get PATH/prompt parity.

$env:EDITOR = 'emacs'

# Prepend Scoop shims and 1Password CLI so they shadow system installs, mirroring env.nu.
$scoopShims = Join-Path $env:USERPROFILE 'scoop\shims'
$onePassword = Join-Path $env:LOCALAPPDATA '1Password\app\8'
foreach ($p in @($scoopShims, $onePassword)) {
    if ($env:Path -notlike "*$p*") { $env:Path = "$p;$env:Path" }
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    $env:STARSHIP_CONFIG = Join-Path $env:USERPROFILE '.config\starship.toml'
    Invoke-Expression (& starship init powershell)
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command atuin -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (atuin init powershell --disable-up-arrow | Out-String) })
}
