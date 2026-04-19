#!/usr/bin/env nu
# Full first-time setup for a new Windows machine.

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

def safe_mklink [dest: string, src: string, --dry-run] {
    let dest = ($dest | path expand)
    let src = ($src | path expand)

    if not ($src | path exists) {
        error make { msg: $"Source path does not exist: ($src)" }
    }

    if $dry_run {
        print $"[DRY RUN] Would link ($dest) -> ($src)"
        return
    }

    # Nushell will automatically quote $dest and $src if they contain spaces.
    # cmd.exe /c will then receive them correctly for the mklink builtin.
    ^cmd.exe /c mklink $dest $src

    if $env.LASTEXITCODE != 0 {
        error make {
            msg: $"Failed to create symlink from ($src) to ($dest).
Ensure you have sufficient privileges or that Developer Mode is enabled.
(Settings > Update & Security > For developers > Developer Mode)"
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main [--dry-run] {
    let dotfiles = ($env.USERPROFILE | path join "dotfiles")
    let nu_config_dir = ($env.APPDATA | path join "nushell")

    if not ($dotfiles | path exists) {
        error make { msg: $"Dotfiles repo not found at ($dotfiles). Please clone it there before running bootstrap." }
    }

    # 1. Verify prerequisites
    section "Checking prerequisites"
    for cmd in ["winget" "nu" "scoop"] { check_command $cmd }
    print "Prerequisites OK."

    # 2. Add Scoop buckets and install CLI tools
    section "Scoop buckets and apps"
    let scoop_manifest = (open ($dotfiles | path join "windows" "scoop.json"))

    for bucket in $scoop_manifest.buckets {
        let installed = (if $dry_run { false } else { (scoop bucket list | lines | any {|l| $l =~ $bucket.Name }) })
        if not $installed {
            if $dry_run {
                print $"[DRY RUN] Would add bucket: ($bucket.Name)"
            } else {
                print $"Adding bucket: ($bucket.Name)"
                scoop bucket add $bucket.Name $bucket.Source
            }
        }
    }

    for app in $scoop_manifest.apps {
        let installed = (if $dry_run { false } else { 
            # scoop list <app> returns exit code 0 if found, 1 if not
            do { scoop list $app.Name } | complete | get exit_code | $in == 0
        })
        if not $installed {
            if $dry_run {
                print $"[DRY RUN] Would install ($app.Name)"
            } else {
                print $"Installing ($app.Name) from ($app.Source)..."
                scoop install $"($app.Source)/($app.Name)"
            }
        } else {
            print $"($app.Name) already installed."
        }
    }

    # 4. Install GUI apps via Winget
    section "Winget apps"
    if $dry_run {
        print "[DRY RUN] Would import winget manifest"
    } else {
        winget import --import-file ($dotfiles | path join "windows" "winget.json") --accept-source-agreements --accept-package-agreements --ignore-versions
    }

    # 5. Symlink config files into their Windows locations
    section "Symlinking config files"

    # Nushell config
    if not $dry_run { mkdir $nu_config_dir }
    let files = {
        "config.nu":   ($dotfiles | path join "home-manager" "config" "config.nu"),
        "env.nu":      ($dotfiles | path join "home-manager" "config" "env.nu"),
        "custom.nu":   ($dotfiles | path join "home-manager" "config" "custom.nu"),
    }

    for pair in ($files | transpose key src) {
        let dest = ($nu_config_dir | path join $pair.key)
        if not ($dest | path exists) {
            print $"Linking ($dest)"
            safe_mklink $dest $pair.src --dry-run=$dry_run
        } else {
            print $"($dest) already exists, skipping."
        }
    }

    # Git config
    let gitconfig_dest = ($env.USERPROFILE | path join ".gitconfig")
    if not ($gitconfig_dest | path exists) {
        print $"Linking ($gitconfig_dest)"
        let src = ($dotfiles | path join "windows" ".gitconfig")
        safe_mklink $gitconfig_dest $src --dry-run=$dry_run
    }

    # WezTerm config
    let wezterm_dest = ($env.USERPROFILE | path join ".wezterm.lua")
    if not ($wezterm_dest | path exists) {
        print $"Linking ($wezterm_dest)"
        let src = ($dotfiles | path join "home-manager" "config" ".wezterm.lua")
        safe_mklink $wezterm_dest $src --dry-run=$dry_run
    }

    # Komorebi config
    let komorebi_dir = ($env.USERPROFILE | path join ".config" "komorebi")
    if not $dry_run { mkdir $komorebi_dir }
    let komorebi_dest = ($komorebi_dir | path join "komorebi.json")
    if not ($komorebi_dest | path exists) {
        print $"Linking ($komorebi_dest)"
        let src = ($dotfiles | path join "windows" "komorebi.json")
        safe_mklink $komorebi_dest $src --dry-run=$dry_run
    }

    # whkd config
    let whkd_dir = ($env.USERPROFILE | path join ".config" "whkd")
    if not $dry_run { mkdir $whkd_dir }
    let whkd_dest = ($whkd_dir | path join "whkdrc")
    if not ($whkd_dest | path exists) {
        print $"Linking ($whkd_dest)"
        let src = ($dotfiles | path join "windows" "whkdrc")
        safe_mklink $whkd_dest $src --dry-run=$dry_run
    }

    # Starship config
    let starship_dir = ($env.USERPROFILE | path join ".config")
    if not $dry_run { mkdir $starship_dir }
    let starship_dest = ($starship_dir | path join "starship.toml")
    if not ($starship_dest | path exists) {
        print $"Linking ($starship_dest)"
        let src = ($dotfiles | path join "home-manager" "config" "starship.toml")
        safe_mklink $starship_dest $src --dry-run=$dry_run
    }

    # 6. Done
    section "Done"
    print "Bootstrap complete. Open a new WezTerm window to verify everything works."
}
