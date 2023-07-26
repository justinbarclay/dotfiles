{ config, lib, pkgs, ... }:

with lib; {
  options.modules.gtk = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.gtk.enable {
    gtk = {
      enable = true;
      theme = {
        name = "Materia-dark";
        package = pkgs.materia-theme;
      };
    };

    home = {
      packages = with pkgs; [
        wl-clipboard-x11
        xdg-utils

        gtk3
        gsettings-desktop-schemas
      ];
    };
  };
}
