{ config, lib, pkgs, ... }:

with lib; {
  options.modules.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    with-gtk = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.emacs.enable
    {
      programs.emacs = {
        enable = true;
        package =
          let
            base = (if pkgs.stdenv.isDarwin then pkgs.emacs-git else pkgs.emacs-igc).override {
              withSQLite3 = true;
              withGTK3 = config.modules.emacs.with-gtk;
              withNativeCompilation = true;
            };
          in
          # On macOS 26 (Tahoe) nixpkgs builds against an older SDK, so the
          # upstream Tahoe scroll-lag fix in nsterm.m is compiled out. Re-enable
          # it with a runtime version check. See ./patches/tahoe-scroll.patch.
          base.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ lib.optional pkgs.stdenv.isDarwin ./patches/tahoe-scroll.patch;
          });
        extraPackages =
          (epkgs: [
            (epkgs.treesit-grammars.with-grammars (ps: lib.filter (p: !p.meta.broken) (lib.attrValues ps)))
            epkgs.auctex
            epkgs.vterm
            epkgs.pdf-tools
            epkgs.mu4e
          ]);
      };
      home.sessionVariables = {
        EDITOR = "emacs";
      };
      home.packages = with pkgs;
        [
          # Needed for network commnunication
          gnutls

          # needed by lsp-mode
          unzip
          # This needs to be around or GTK gets mad about the themes displayed
          #
          # Used by magit
          sqlite
          # used by gcc
          # binutils
          # Needed for things like custom treesitter builds or vterm
          gcc

          # Let's spell good
          hunspell
          hunspellDicts.en_CA

          ltex-ls
          harper
          leetcode-cli
          # Dirvish
          coreutils
          fd
          ffmpeg
          ffmpegthumbnailer
          poppler

          cloc

          # aider-chat

          vale-ls
          vale

          emacs-lsp-booster
        ];
    };
}
