{ config, lib, pkgs, ... }:

with lib; {
  options.modules.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.emacs.enable {
    home.packages = with pkgs; [
      # Needed for network commnunication
      gnutls

      # Use by magit
      sqlite
      gtk3
      gsettings-desktop-schemas
      # used by gcc
      binutils

      (emacsGit.override {
        withGTK3 = true;
        withXwidgets = true;
      })
      emacs-all-the-icons-fonts

      # Dirvish
      ffmpeg
      ffmpegthumbnailer
      poppler
      rnix-lsp
    ];

    services.gpg-agent = {
      enable = true;
      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };
  };
}
