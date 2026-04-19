#!/usr/bin/env nu
# Full first-time setup for a new Windows machine.
#
# Do NOT run this directly on a machine that doesn't have Nushell yet.
# Use the PowerShell pre-bootstrap instead — it installs Nushell and then
# calls this script automatically:
#
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\windows\bootstrap.ps1
#
# If Nushell is already installed you can also invoke this directly:
#   nu windows/bootstrap.nu

let dotfiles = ($env.USERPROFILE | path join "dotfiles")
let nu_config_dir = ($env.APPDATA | path join "nushell")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def check_command [cmd: string] {
    if (which $cmd | is-empty) {
        error make { msg: $"Required command not found: ($cmd). Please install it before running bootstrap." }
    }
}

def section [title: string] {
    print $"\n\e[1;36m== ($title) ==\e[0m"
}

def safe_mklink [dest: string, src: string] {
    cmd.exe /c $"mklink \"($dest)\" \"($src)\""
    if $env.LASTEXITCODE != 0 {
        error make {
            msg: $"Failed to create symlink from ($src) to ($dest).
Ensure you have sufficient privileges or that Developer Mode is enabled.
(Settings > Update & Security > For developers > Developer Mode)"
        }
    }
}

# ---------------------------------------------------------------------------
# 1. Verify prerequisites
# ---------------------------------------------------------------------------
section "Checking prerequisites"
# Note: this script assumes it is being run from an existing checked-out
# dotfiles working tree. Cloning the repo, if needed, happens before this
# script is invoked, so git is not checked here.
# winget should be available when entering via bootstrap.ps1, and we verify it
# here along with Nushell.
for cmd in ["winget" "nu"] { check_command $cmd }
print "Prerequisites OK."

# ---------------------------------------------------------------------------
# 2. Install Scoop (if missing)
# ---------------------------------------------------------------------------
section "Scoop"
if (which scoop | is-empty) {
    print "Installing Scoop..."
    powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
    # Re-source PATH so scoop shims are visible in this session
    $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.USERPROFILE)\\scoop\\shims")
} else {
    print "Scoop already installed."
}

# ---------------------------------------------------------------------------
# 3. Add Scoop buckets and install CLI tools
# ---------------------------------------------------------------------------
section "Scoop buckets and apps"
let scoop_manifest = (open ($dotfiles | path join "windows" "scoop.json"))

for bucket in $scoop_manifest.buckets {
    let installed = (scoop bucket list | lines | any {|l| $l =~ $bucket.Name })
    if not $installed {
        print $"Adding bucket: ($bucket.Name)"
        scoop bucket add $bucket.Name $bucket.Source
    }
}

for app in $scoop_manifest.apps {
    let installed = (scoop list | from ssv --noheaders | get column1 | any {|n| $n == $app.Name })
    if not $installed {
        print $"Installing ($app.Name) from ($app.Source)..."
        scoop install $"($app.Source)/($app.Name)"
    } else {
        print $"($app.Name) already installed."
    }
}

# ---------------------------------------------------------------------------
# 4. Install GUI apps via Winget
# ---------------------------------------------------------------------------
section "Winget apps"
winget import --import-file ($dotfiles | path join "windows" "winget.json") --accept-source-agreements --accept-package-agreements --ignore-versions

# ---------------------------------------------------------------------------
# 5. Symlink config files into their Windows locations
# ---------------------------------------------------------------------------
section "Symlinking config files"

# Nushell config
mkdir $nu_config_dir
let files = {
    "config.nu":   ($dotfiles | path join "home-manager" "config" "config.nu"),
    "env.nu":      ($dotfiles | path join "home-manager" "config" "env.nu"),
    "windows.nu":  ($dotfiles | path join "home-manager" "config" "windows.nu"),
}

for pair in ($files | transpose key src) {
    let dest = ($nu_config_dir | path join $pair.key)
    if not ($dest | path exists) {
        print $"Linking ($dest)"
        safe_mklink $dest $pair.src
    } else {
        print $"($dest) already exists, skipping."
    }
}

# Git config
let gitconfig_dest = ($env.USERPROFILE | path join ".gitconfig")
if not ($gitconfig_dest | path exists) {
    print $"Linking ($gitconfig_dest)"
    let src = ($dotfiles | path join "windows" ".gitconfig")
    safe_mklink $gitconfig_dest $src
}

# WezTerm config (WezTerm on Windows reads from %USERPROFILE%/.config/wezterm/ or %USERPROFILE%/.wezterm.lua)
let wezterm_dest = ($env.USERPROFILE | path join ".wezterm.lua")
if not ($wezterm_dest | path exists) {
    print $"Linking ($wezterm_dest)"
    let src = ($dotfiles | path join "home-manager" "config" ".wezterm.lua")
    safe_mklink $wezterm_dest $src
}

# Komorebi config
let komorebi_dir = ($env.USERPROFILE | path join ".config" "komorebi")
mkdir $komorebi_dir
let komorebi_dest = ($komorebi_dir | path join "komorebi.json")
if not ($komorebi_dest | path exists) {
    print $"Linking ($komorebi_dest)"
    let src = ($dotfiles | path join "windows" "komorebi.json")
    safe_mklink $komorebi_dest $src
}

# whkd config
let whkd_dir = ($env.USERPROFILE | path join ".config" "whkd")
mkdir $whkd_dir
let whkd_dest = ($whkd_dir | path join "whkdrc")
if not ($whkd_dest | path exists) {
    print $"Linking ($whkd_dest)"
    let src = ($dotfiles | path join "windows" "whkdrc")
    safe_mklink $whkd_dest $src
}

# Starship config
let starship_dir = ($env.USERPROFILE | path join ".config")
mkdir $starship_dir
let starship_dest = ($starship_dir | path join "starship.toml")
if not ($starship_dest | path exists) {
    print $"Linking ($starship_dest)"
    let src = ($dotfiles | path join "home-manager" "config" "starship.toml")
    safe_mklink $starship_dest $src
}

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
section "Done"
print "Bootstrap complete. Open a new WezTerm window to verify everything works."
print "Run `windows/update.nu` at any time to upgrade all packages."
