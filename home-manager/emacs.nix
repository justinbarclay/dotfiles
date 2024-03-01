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

          (emacs-git.override {
            withSQLite3 = true;
            withGTK3 = config.modules.emacs.with-gtk;
            withXwidgets = config.modules.emacs.with-gtk;
          })

          # Let's spell good
          hunspell
          hunspellDicts.en_CA

          emacsPackages.mu4e
          emacsPackages.auctex
          # Dirvish
          coreutils
          fd
          ffmpeg
          ffmpegthumbnailer
          poppler
          rnix-lsp
        ];
    };
}
