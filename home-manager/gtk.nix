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
        name = "Tokyo Night";
        package = pkgs.tokyonight-gtk-theme;
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
