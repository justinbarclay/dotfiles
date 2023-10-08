{ pkgs, lib, ... }:
{
  imports = [ ./services/postgres.nix ./services/redis.nix ./services/pueue.nix ];

  modules.darwin.postgres = {
    enable = false;
    user = "justin";
  };
  modules.darwin.pueue = {
    enable = true;
  };
  modules.darwin.redis = {
    enable = true;
  };
  # Nix configuration ------------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  users.users = {
    justin = {
      name = "justin";
      shell = pkgs.nushell;
      home = "/Users/justin";
    };
  };

  nix = {
    extraOptions = ''
      extra-nix-path = nixpkgs=flake:nixpkgs
      bash-prompt-prefix = (nix:$name)
      experimental-features = nix-command flakes auto-allocate-uids
    '';
    settings = {
      trusted-users = [ "root" "justin" ];
      auto-optimise-store = true;
    };
    gc.automatic = true;
  };

  # Enable experimental nix command and flake

  # Create /etc/.zshrc that loads the nix-darwin environment.
  programs.zsh = {
    enable = true;
    loginShellInit = ''
      if [[ $- == *i* ]]; then
        exec nu "$@"
      fi
    '';
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.activate-system.enable = true;
  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs; [
    git
    bat
    ripgrep
    wget
    curl
    eza
    man-pages
    man-pages-posix
    ripgrep
    wezterm
    nushell
    spotify
    discord
  ];
  # So we also use homebrew for GUI packages we want to launch through spotlight/raycast
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    # Unfortunately we need to create the postgres superuser ourselves
    # `CREATE USER postgres SUPERUSER;`
    brews = [{
      name = "postgresql@13";
      restart_service = true;
      start_service = true;
      link = true;
      conflicts_with = [ "postgresql" ];
    }

      # Need to write a podman service
      {
        name = "podman";
        link = true;
        restart_service = true;
        start_service = true;
      }];
    casks = [ "rectangle" "topnotch" "hiddenbar" "raycast" "drata-agent" "1password-cli" "microsoft-edge" "docker" ];
  };

  environment.darwinConfig = "$HOME/dotfiles/home-manager";
  environment.shells = [ pkgs.nushell pkgs.zsh pkgs.bashInteractive ];
  environment.shellAliases = {
    docker = "podman";
  };
  # https://github.com/nix-community/home-manager/issues/423
  programs.nix-index.enable = true;

  # Fonts
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ nerdfonts powerline-fonts ];

  # Darwin System configuration
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;

    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
        show-recents = false;
        launchanim = true;
      };
      smb.NetBIOSName = "Heimdall";
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = false;
        FXEnableExtensionChangeWarning = false;
      };
      trackpad = {
        TrackpadRightClick = true;
        Clicking = true;
      };
    };
  };
  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;
}
