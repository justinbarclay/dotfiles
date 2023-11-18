{ lib, pkgs, config, ... }:

with builtins;
with lib; {
  config = {
    wsl = {
      enable = true;
      wslConf.automount.root = "/mnt";
      defaultUser = "justin";
      startMenuLaunchers = true;
      nativeSystemd = true;
    };

    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings = {
        trusted-users = [ "root" "justin" ];
        auto-optimise-store = true;
      };
    };

    users.users.justin = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
    };
    time.timeZone = "America/Vancouver";
    fonts.fontconfig = {
      enable = true;
      # https://nixos.wiki/wiki/Fonts#Use_custom_font_substitutions
      localConf = ''
        <dir>/mnt/c/Windows/Fonts</dir>
      '';
    };
    fonts.packages = with pkgs; [ nerdfonts powerline-fonts ];
    i18n.defaultLocale = "en_CA.UTF-8";

    programs.zsh = {
      enable = true;
      loginShellInit = ''
        if [[ $- == *i* ]]; then
          exec nu "$@"
        fi
      '';
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
        wget
        curl
        eza
        wsl-open
        man-pages
        man-pages-posix
      ];
      variables = rec {
        BROWSER = "wsl-open";
      };
    };
    # security.pki.certificateFiles = [ /home/justin/dev/tidal/application-inventory/Tidal-RootCA/Tidal-RootCA.crt ];
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
    };

    services = {
      tailscale.enable = true;
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
    system.stateVersion = "23.11";
  };
}
