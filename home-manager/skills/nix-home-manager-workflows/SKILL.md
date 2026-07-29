---
name: nix-home-manager-workflows
description: Use when editing Nix code, home-manager configurations, dotfiles under ~/dotfiles/home-manager/, flake definitions, or managing system/user configuration deployments.
---

# Nix & Home-Manager Workflow Guidelines

Enforce declarative configuration discipline when managing user environment, Nix flakes, packages, and home-manager modules under `~/dotfiles/home-manager/`.

## Core Rules

1. **Source Edit Rule (NEVER EDIT SYMLINKS DIRECTLY)**:
   - Deployed configuration files (`~/.config/*`, `~/.zshrc`, etc.) are read-only symlinks into `/nix/store`. NEVER attempt to edit, force-write, or modify deployed files in place.
   - ALWAYS edit the underlying source `.nix` files under `~/dotfiles/home-manager/`.
2. **Deployment via Home-Manager Switch**:
   - To apply changes, build and switch using `home-manager switch`.
3. **Modular Nix Structure**:
   - Keep domain concerns isolated in focused `.nix` files under `~/dotfiles/home-manager/` (e.g. `llm.nix`, `git.nix`, `zsh.nix`, `home.nix`).
   - Use `builtins.readFile` or `builtins.toJSON` to generate target file contents declaratively.
4. **Package Derivations**:
   - Prefer `pkgs.callPackage ./packages/... { }` for custom local tools/packages.

## Completion Criteria

The Nix/home-manager task is complete when:
- All edits are strictly committed to source files under `~/dotfiles/home-manager/`.
- No read-only symlinks in `~/.config/` or `/nix/store` were touched directly.
- Configuration passes evaluation and builds cleanly with `home-manager switch`.
