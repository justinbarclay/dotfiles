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

      # used by gcc
      binutils

      emacsGitNativeComp
      emacs-all-the-icons-fonts

      # Needed to bootstrap the rest of emacs
      emacs28Packages.use-package

      # Dirvish
      ffmpeg
      ffmpegthumbnailer
      poppler
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
