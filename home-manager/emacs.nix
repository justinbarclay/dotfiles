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
        package = pkgs.emacs-git.override {
          withSQLite3 = true;
          withGTK3 = config.modules.emacs.with-gtk;
          # withXwidgets = config.modules.emacs.with-gtk;
        };
        extraPackages = (epkgs: [ epkgs.treesit-grammars.with-all-grammars epkgs.mu4e epkgs.auctex ]);
      };
      home.sessionVariables = {
        EDITOR = "emacs";
      };
      home.packages = with pkgs;
        [
          # Needed for network commnunication
          gnutls

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

          # code-compass
          python3
          cloc
          gource
          zulu23
          code-maat
        ];
    };
}
