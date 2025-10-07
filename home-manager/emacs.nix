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
        package = pkgs.emacs-igc.override {
          withSQLite3 = true;
          withGTK3 = config.modules.emacs.with-gtk;
          withNativeCompilation = pkgs.stdenv.isLinux;
        };
        extraPackages =
          (epkgs: [
            epkgs.treesit-grammars.with-all-grammars
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
          nil

          cloc

          aider-chat

          vale-ls
          vale

          gemini-cli
        ];
    };
}
