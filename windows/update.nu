#!/usr/bin/env nu
# Upgrade all Windows package managers and re-export declarative manifests.
# Equivalent to `rebuild-darwin` / `rebuild-nix` on the other platforms.
#
# Usage:  nu windows/update.nu

let dotfiles = ($env.USERPROFILE | path join "dotfiles")

def section [title: string] {
    print $"\n\e[1;36m== ($title) ==\e[0m"
}

# ---------------------------------------------------------------------------
# 1. Upgrade Winget packages
# ---------------------------------------------------------------------------
section "Winget upgrade"
do -i { winget upgrade --all --accept-source-agreements --accept-package-agreements }

# ---------------------------------------------------------------------------
# 2. Update Scoop itself, then all installed apps
# ---------------------------------------------------------------------------
section "Scoop update"
do -i { scoop update }
do -i { scoop update "*" }

# ---------------------------------------------------------------------------
# 3. Filter and Export Winget packages to packages.json
# ---------------------------------------------------------------------------
section "Exporting and filtering Winget packages"

# Export all winget packages to a temporary file
let temp_export = ($env.TEMP | path join "winget-export-temp.json")
if ($temp_export | path exists) { rm -f $temp_export }
winget export --output $temp_export --accept-source-agreements

# Load the exported packages
let data = (open $temp_export)

# Define denylist for system packages, runtime libraries, and hardware drivers
let denylist = [
  "^Microsoft\\.VCRedist"
  "^Microsoft\\.DotNet"
  "^Microsoft\\.UI\\.Xaml"
  "^Microsoft\\.VCLibs"
  "^Microsoft\\.WindowsAppRuntime"
  "^Microsoft\\.DirectX"
  "^Microsoft\\.GameInput"
  "^Microsoft\\.msmpi"
  "^Microsoft\\.AppInstaller"
  "^Microsoft\\.Edge"
  "^Microsoft\\.Teams"
  "^Nvidia\\."
  "^ViGEm\\."
  "^MOTU\\."
  "^Bose\\."
  "^Dell\\."
  "^PlayStation\\."
  "^Logitech\\."
  "^LGUG2Z\\.komorebi"
  "^wez\\.wezterm"
]

# Filter packages
let new_sources = ($data.Sources | each {|source|
  let filtered = ($source.Packages | where {|pkg|
    let id = $pkg.PackageIdentifier
    $denylist | all {|pattern| ($id !~ $pattern) }
  })
  $source | update Packages $filtered
})

let filtered_data = ($data | update Sources $new_sources)

# Save directly to packages.json
$filtered_data | to json | save --force ($dotfiles | path join "windows" "packages.json")
rm -f $temp_export

print "packages.json updated with filtered Winget packages."

# ---------------------------------------------------------------------------
# 4. Export Scoop packages cleanly to scoop.json
# ---------------------------------------------------------------------------
section "Exporting Scoop packages"

let scoop_raw = (scoop export | from json)
let existing_scoop = if (($dotfiles | path join "windows" "scoop.json") | path exists) {
  open ($dotfiles | path join "windows" "scoop.json")
} else {
  { apps: [], buckets: [] }
}
let existing_apps = ($existing_scoop.apps? | default [])

let clean_buckets = ($scoop_raw.buckets? | default [] | each {|b|
  {
    Name: $b.Name,
    Source: (($b.Source? | default "") | str replace -r '\.git$' "")
  }
})

let clean_apps = ($scoop_raw.apps? | default [] | where {|a|
  let is_failed = (($a.Info? | default "") | str contains -i "Install failed")
  let was_tracked = ($existing_apps | any {|e| $e.Name == $a.Name })
  (not $is_failed) or $was_tracked
} | each {|a|
  let prev_source = ($existing_apps | where Name == $a.Name | get -o 0.Source)
  let src = if not ($a.Source? | is-empty) {
    $a.Source?
  } else if not ($prev_source | is-empty) {
    $prev_source
  } else {
    "main"
  }
  { Name: $a.Name, Source: $src }
})

let clean_scoop = { buckets: $clean_buckets, apps: $clean_apps }

$clean_scoop | to json | save --force ($dotfiles | path join "windows" "scoop.json")

print "scoop.json updated with current Scoop packages."

# ---------------------------------------------------------------------------
# 5. Remind to commit
# ---------------------------------------------------------------------------
section "Done"
print "Packages upgraded and manifests updated."
print "Review the changes and commit:"
print "  git -C $dotfiles diff windows/"
