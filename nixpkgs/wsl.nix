{ lib, pkgs, config, ... }:

with builtins;
with lib; {
  config = {
    nix.settings.auto-optimise-store = true;
    users.users.justin = {
      isNormalUser = true;
      shell = pkgs.nushell;
      extraGroups = [ "wheel" "docker" ];
    };
    time.timeZone = "America/Vancouver";
    fonts.fontconfig.enable = true;
    fonts.fonts = with pkgs; [ nerdfonts powerline-fonts ];
    i18n.defaultLocale = "en_CA.UTF-8";

    programs.zsh = {
      shellAliases =
        {
          ssh = "ssh.exe";
          ssh-add = "ssh-add.exe";
        };
    };
    programs.dconf.enable = true;
    environment = {
      systemPackages = with pkgs; [
        git
        bat
        ripgrep
        exa
        wsl-open
        man-pages
        man-pages-posix
      ];
      variables = rec {
        BROWSER = "wsl-open";
      };
    };

    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_13;
        enableTCPIP = true;
        authentication = pkgs.lib.mkOverride 13 ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
      };
      # Use "" to start a standard redis instance
      redis.servers."".enable = true;
      redis.servers."".openFirewall = true;
    };
  };
}
