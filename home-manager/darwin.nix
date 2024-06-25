{ pkgs, lib, ... }:
{
  imports = [ ./services/postgres.nix ./services/redis.nix ./services/pueue.nix ./services/mbsync.nix ];

  modules.darwin.postgres = {
    enable = true;
    user = "justin";
  };
  modules.darwin.pueue = {
    enable = true;
  };
  modules.darwin.redis = {
    enable = true;
  };

  modules.darwin.mbsync = {
    enable = true;
    postExec = "${pkgs.mu}/bin/mu index";
  };
  # Nix configuration ------------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  users.users = {
    justin = {
      name = "justin";
      shell = pkgs.nushell;
      home = "/Users/justin";
    };
    postgres = {
      name = "postgres";
      home = "/Users/postgres";
      description = "PostgreSQL user";
      # "/Users/justin/Library/Application Support/Postgresql/.keep".text = "";
    };
  };
  nix = {
    linux-builder = {
      enable = false;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 6;
        };
      };
    };
    extraOptions = ''
      extra-nix-path = nixpkgs=flake:nixpkgs
      bash-prompt-prefix = (nix:$name)
      experimental-features = nix-command flakes auto-allocate-uids
    '';
    settings = {
      trusted-users = [ "root" "justin" "@admin" ];
      auto-optimise-store = true;
      extra-trusted-users = "justin";
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
  services = {
    nix-daemon.enable = true;
    postgresql.enable = true;
    activate-system.enable = true;
    tailscale.enable = true;
  };

  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs; [
    _1password
    bat
    curl
    discord
    eza
    git
    lldb_16
    # man-pages
    # man-pages-posix
    nixos-rebuild
    nushell
    ripgrep
    spotify
    wezterm
    wget
    zellij
    (pkgs.writeScriptBin "rebuild-darwin"
      ''
        nix flake update ~/dotfiles/home-manager
        darwin-rebuild switch --flake ~/dotfiles/home-manager
      '')
  ];
  # So we also use homebrew for GUI packages we want to launch through spotlight/raycast
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = false;
    onActivation.upgrade = true;

    # Unfortunately we need to create the postgres superuser ourselves
    # `CREATE USER postgres SUPERUSER;`
    brews = [
      {
        name = "pngpaste";
        link = true;
      }
    ];
    casks = [
      "rectangle"
      "topnotch"
      "hiddenbar"
      "raycast"
      "drata-agent"
      "docker"
      "vlc"
      "kap"
      "istat-menus"
      "keycastr"
      "calibre"
    ];
  };

  environment.darwinConfig = "$HOME/dotfiles/home-manager";
  environment.shells = [ pkgs.nushell pkgs.zsh pkgs.bashInteractive ];

  # https://github.com/nix-community/home-manager/issues/423
  programs.nix-index.enable = true;

  # Fonts
  fonts.packages = with pkgs; [ nerdfonts powerline-fonts ];

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
