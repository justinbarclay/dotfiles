#!/usr/bin/env nu
# Bootstrap a new Windows machine from this dotfiles repository.
#
# Prerequisites (install these manually first):
#   - Nushell   https://github.com/nushell/nushell/releases
#   - Git       https://git-scm.com/downloads/win
#   - WezTerm   https://wezfurlong.org/wezterm/installation.html
#   - 1Password https://1password.com/downloads/windows/
#
# Then clone the repo and run:
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

# ---------------------------------------------------------------------------
# 1. Verify prerequisites
# ---------------------------------------------------------------------------
section "Checking prerequisites"
for cmd in ["winget" "git" "nu"] { check_command $cmd }
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
        cmd.exe /c mklink $dest $pair.src
    } else {
        print $"($dest) already exists, skipping."
    }
}

# Git config
let gitconfig_dest = ($env.USERPROFILE | path join ".gitconfig")
if not ($gitconfig_dest | path exists) {
    print $"Linking ($gitconfig_dest)"
    cmd.exe /c mklink $gitconfig_dest ($dotfiles | path join "windows" ".gitconfig")
}

# WezTerm config (WezTerm on Windows reads from %USERPROFILE%/.config/wezterm/ or %USERPROFILE%/.wezterm.lua)
let wezterm_dest = ($env.USERPROFILE | path join ".wezterm.lua")
if not ($wezterm_dest | path exists) {
    print $"Linking ($wezterm_dest)"
    cmd.exe /c mklink $wezterm_dest ($dotfiles | path join "home-manager" "config" ".wezterm.lua")
}

# Komorebi config
let komorebi_dir = ($env.USERPROFILE | path join ".config" "komorebi")
mkdir $komorebi_dir
let komorebi_dest = ($komorebi_dir | path join "komorebi.json")
if not ($komorebi_dest | path exists) {
    print $"Linking ($komorebi_dest)"
    cmd.exe /c mklink $komorebi_dest ($dotfiles | path join "windows" "komorebi.json")
}

# whkd config
let whkd_dir = ($env.USERPROFILE | path join ".config" "whkd")
mkdir $whkd_dir
let whkd_dest = ($whkd_dir | path join "whkdrc")
if not ($whkd_dest | path exists) {
    print $"Linking ($whkd_dest)"
    cmd.exe /c mklink $whkd_dest ($dotfiles | path join "windows" "whkdrc")
}

# Starship config
let starship_dir = ($env.USERPROFILE | path join ".config")
mkdir $starship_dir
let starship_dest = ($starship_dir | path join "starship.toml")
if not ($starship_dest | path exists) {
    print $"Linking ($starship_dest)"
    cmd.exe /c mklink $starship_dest ($dotfiles | path join "home-manager" "config" "starship.toml")
}

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
section "Done"
print "Bootstrap complete. Open a new WezTerm window to verify everything works."
print "Run `windows/update.nu` at any time to upgrade all packages."
