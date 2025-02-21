{ lib, pkgs, config, ... }:
with builtins;
with lib; {
  config = {
    wsl = {
      enable = true;
      wslConf.automount.root = "/mnt";
      defaultUser = "justin";
      startMenuLaunchers = true;
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
      extraGroups = [ "wheel" "docker" "podman" ];
    };
    time.timeZone = "America/Vancouver";
    fonts = {
      fontconfig = {
        enable = true;
        hinting.style = "full";
        # https://nixos.wiki/wiki/Fonts#Use_custom_font_substitutions
        localConf = ''
          <dir>/mnt/c/Windows/Fonts</dir>
        '';
      };
    };
    fonts.packages = with pkgs; [
      roboto-mono
      nerd-fonts.caskaydia-mono
      yanone-kaffeesatz
      powerline-fonts
    ];
    i18n. defaultLocale = "en_CA.UTF-8";

    programs = {
      zsh = {
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

      dconf.enable = true;

      nix-ld = {
        enable = true;
        package = pkgs.nix-ld-rs;
      };
    };

    environment = {
      systemPackages = with pkgs;
        [
          # use the windows variant off ssh for better interaction with 1Password's SSH agent.
          (pkgs.writeScriptBin "ssh"
            ''
              /mnt/c/Windows/System32/OpenSSH/ssh.exe "$@"
            '')
          # nushell
          git
          bat
          ripgrep
          wget
          curl
          eza
          wsl-open
          man-pages
          man-pages-posix
          home-manager
          nushell

          (pkgs.writeScriptBin "rebuild-nix"
            ''
              sudo nixos-rebuild --flake /home/justin/dotfiles/home-manager#"vider" switch --impure
            '')
        ];

      variables = rec {
        BROWSER = "wsl-open";
      };
    };

    virtualisation.podman = {
      enable = true;
      # dockerCompat = true;
      # dockerSocket.enable = true;
    };
    virtualisation.docker = {
      enable = true;
      # extraOptions = ''
      #   experimental: true
      # '';
      # extraGroups = [ "docker" ];
      # socketGroup = "docker";
      # socketMode = "0660";
    };
    services = {
      tailscale.enable = true;
      postgresql = {
        enable = true;
        package = pkgs.postgresql_16;
        enableTCPIP = true;
        authentication = pkgs.lib.mkOverride 16 ''
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
