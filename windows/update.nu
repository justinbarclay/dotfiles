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
winget upgrade --all --accept-source-agreements --accept-package-agreements

# ---------------------------------------------------------------------------
# 2. Update Scoop itself, then all installed apps
# ---------------------------------------------------------------------------
section "Scoop update"
scoop update
scoop update "*"

# ---------------------------------------------------------------------------
# 3. Re-export manifests so the repo stays in sync
# ---------------------------------------------------------------------------
section "Re-exporting manifests"
winget export --output ($dotfiles | path join "windows" "packages.json") --accept-source-agreements
print "packages.json updated."

# Scoop export produces the same JSON shape we import from
scoop export | save --force ($dotfiles | path join "windows" "scoop.json")
print "scoop.json updated."

# ---------------------------------------------------------------------------
# 4. Remind to commit
# ---------------------------------------------------------------------------
section "Done"
print "Packages upgraded and manifests re-exported."
print "Review the diff and commit if the changes look right:"
print "  git -C $dotfiles diff windows/"
