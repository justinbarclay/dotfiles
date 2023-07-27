{ pkgs, lib, ... }:
{

  imports = [ ./services/postgres.nix ];

  modules.darwin.postgres = {
    enable = false;
    user = "justin";
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
    exa
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
    brews = [{
      name = "postgresql@13";
      restart_service = true;
      link = true;
      conflicts_with = [ "postgresql" ];
    }];
    casks = [ "rectangle" "topnotch" "bartender" "raycast" "drata-agent" ];
  };

  environment.darwinConfig = "$HOME/dotfiles/home-manager";
  environment.shells = [ pkgs.nushell pkgs.zsh pkgs.bashInteractive ];
  # https://github.com/nix-community/home-manager/issues/423
  programs.nix-index.enable = true;

  # Fonts
  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [ nerdfonts powerline-fonts ];

  services = {
    redis = {
      enable = true;
      bind = "localhost";
      # must manually run
      # `sudo mkdir /var/lib/redis`
    };
  };
  # Darwin System configuration
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;

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
