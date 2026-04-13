{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    devenv.url = "github:cachix/devenv/latest";
    tidal-overlay = {
      url = "git+ssh://git@github.com/tidalmigrations/aws-sso";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tidal-tools = {
      url = "git+ssh://git@github.com/tidalmigrations/tidal-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-lsp-booster = {
      url = "github:slotThe/emacs-lsp-booster-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , tidal-overlay
    , nixos-wsl
    , nix-darwin
    , tidal-tools
    , emacs-lsp-booster
    , determinate
    , ...
    }:
    let
      user = "justin";

      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "6727826cfa556a7b79afc2e30ad52acb6ce6e53c";
      });

      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration
        {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
            overlays = [
              (final: prev:
                {
                  tidal = tidal-tools;
                  direnv = (import nixpkgs-stable { inherit system; }).direnv;
                })
              emacs-overlay
              tidal-overlay.overlays.default
              emacs-lsp-booster.overlays.default

              (
                _final: _prev:
                  # On macOS, the emacs-git pdmp (portable dump) captures the Nix build
                  # sandbox path (/private/tmp/nix-build-.../etc) as data-directory.
                  # When emacs is later used as a build tool for elisp packages, the new
                  # sandbox returns EPERM (not ENOENT) for that stale temp path — causing
                  # a fatal startup crash before EMACSDATA env var processing in startup.el.
                  #
                  # Fix: re-dump emacs immediately after install (while still inside the
                  # build sandbox where those paths are accessible), with EMACSDATA and
                  # native-comp-eln-load-path corrected to point at $out store paths.
                  # The new pdmp captures the corrected values, eliminating the EPERM.
                  if _prev.stdenv.isDarwin then
                    {
                      emacs-igc =
                        let
                          emacs = _final.emacs-igc;
                          base = _prev.emacs-igc.overrideAttrs (old: {
                            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ _prev.makeWrapper ];
                            postInstall = (old.postInstall or "") + ''
                              emacs_version=$(ls "$out/share/emacs" | grep -E '^[0-9]' | sort -V | tail -1)
                              old_pdmp=$(find "$out/libexec/emacs/$emacs_version" -name 'emacs-*.pdmp' 2>/dev/null | head -1)
                              if [ -n "$old_pdmp" ]; then
                                tmp_pdmp="$old_pdmp.tmp"
                                eln_dir="$out/lib/emacs/$emacs_version/native-lisp"
                                elisp_file=$(mktemp "$TMPDIR/emacs-redump-XXXXXX.el")
                                cat > "$elisp_file" << ELISP
                              ; Fix pdmp-frozen variables that point to the build sandbox.
                              (when (boundp 'native-comp-eln-load-path)
                                (setq native-comp-eln-load-path (list "$eln_dir/")))
                              (setq temporary-file-directory "/tmp/")
                              ; source-directory captures the unpacked build tree path. Emacs source
                              ; is not installed to the store, but $out is a better fallback than a
                              ; stale sandbox path — prevents "Listing directory failed" errors from
                              ; xref/find-function trying to scan the missing build dir.
                              (setq source-directory "$out/")
                              ; package-directory-list is frozen in the pdmp at emacs-git build time
                              ; when no user packages are present. When this emacs is later used to
                              ; build elisp packages, EMACSLOADPATH adds deps to load-path but
                              ; package-directory-list (already bound → defcustom is a no-op) does
                              ; not include their elpa dirs, so package-activate-all cannot find deps.
                              ;
                              ; Fix: use with-eval-after-load so that AFTER package.el loads (triggered
                              ; by the -f package-activate-all autoload), we reset package-directory-list
                              ; from the current load-path (which includes EMACSLOADPATH additions) and
                              ; call package-initialize to populate package-alist.
                              ;
                              ; NOTE: advice-add before package.el loads is wiped when defun redefines
                              ; the symbol; with-eval-after-load ensures the hook runs after defun.
                              ; Gate on noninteractive: in interactive Emacs, package-activate-all is
                              ; called at startup which triggers this hook and resets package-alist,
                              ; breaking package activation (org-mode not rendering, treesit nil, etc.).
                              ; Only batch/build-time invocations need this fix.
                              (with-eval-after-load 'package
                                (when noninteractive
                                  (setq package-directory-list
                                    (let (result)
                                      (dolist (f load-path)
                                        (and (stringp f)
                                             (equal (file-name-nondirectory f) "site-lisp")
                                             (push (expand-file-name "elpa" f) result)))
                                      (nreverse result)))
                                  (unless (bound-and-true-p package--initialized)
                                    (package-initialize t))))
                              ; Re-enable global minor modes that batch mode leaves disabled but
                              ; the original pdmp (built by loadup.el) had enabled. Without this,
                              ; interactive Emacs inherits the batch-mode nil state.
                              (global-font-lock-mode 1)
                              (transient-mark-mode 1)
                              (dump-emacs-portable "$tmp_pdmp")
                              ELISP
                                EMACSDATA="$out/share/emacs/$emacs_version/etc" \
                                EMACSLOADPATH="$out/share/emacs/$emacs_version/lisp:" \
                                  "$out/bin/emacs" \
                                    --dump-file "$old_pdmp" \
                                    --batch \
                                    --no-site-file \
                                    --load "$elisp_file" \
                                  && mv "$tmp_pdmp" "$old_pdmp" \
                                  || echo "Warning: emacs re-dump failed, continuing with original pdmp"
                                rm -f "$elisp_file"
                              fi
                              wrapProgram "$out/bin/emacs" \
                                --set-default EMACSDATA "$out/share/emacs/$emacs_version/etc"
                            '';
                          });
                        in
                        base.overrideAttrs (oa: {
                          passthru = oa.passthru // {
                            pkgs = oa.passthru.pkgs.overrideScope (_eself: _esuper: { inherit emacs; });
                          };
                        });
                    }
                  else
                    { }
              )
            ];
          };
          extraSpecialArgs = {
            inherit system;
            inherit user;
          };
          modules = [ ./home.nix ];
        };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations."vider" = lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = [ nixos-wsl.nixosModules.wsl ./wsl.nix ];
        };

      darwinConfigurations."heimdall" = nix-darwin.lib.darwinSystem
        {
          system = "aarch64-darwin";
          modules = [
            determinate.darwinModules.default
            ./darwin.nix
          ];
        };
      homeConfigurations."justin@nixos" = mkHomeConfig "x86_64-linux";
      homeConfigurations."justin@heimdall" = mkHomeConfig "aarch64-darwin";
    };
}
