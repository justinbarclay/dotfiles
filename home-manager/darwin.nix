{ pkgs, lib, ... }:
{
  imports = [ ./services/redis.nix ./services/pueue.nix ./services/mbsync.nix ];

  modules.darwin.pueue = {
    enable = true;
  };
  modules.darwin.redis = {
    enable = true;
  };
  modules.darwin.mbsync = {
    enable = false;
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
  };

  ids.gids.nixbld = 30000;

  nix = {
    # use determinate nix to manage nix
    enable = false;
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
      extra-trusted-users = "justin";
    };
    optimise.automatic = false;
    gc.automatic = false;
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
    aerospace = {
      enable = true;
      settings = {
        gaps = {
          outer.left = 0;
          outer.right = 0;
          outer.bottom = 0;
          outer.top = 0;
          inner.horizontal = 0;
          inner.vertical = 0;
        };
        mode.main.binding = {
          cmd-ctrl-alt-comma = "mode service";

          cmd-ctrl-alt-1 = "workspace 1";
          cmd-ctrl-alt-2 = "workspace 2";
          cmd-ctrl-alt-3 = "workspace 3";
          cmd-ctrl-alt-c = "workspace c";
          cmd-ctrl-alt-e = "workspace e";
          cmd-ctrl-alt-t = "workspace t";

          cmd-ctrl-alt-shift-1 = "move-node-to-workspace 1";
          cmd-ctrl-alt-shift-2 = "move-node-to-workspace 2";
          cmd-ctrl-alt-shift-3 = "move-node-to-workspace 3";
          cmd-ctrl-alt-shift-c = "move-node-to-workspace c";
          cmd-ctrl-alt-shift-e = "move-node-to-workspace e";
          cmd-ctrl-alt-shift-t = "move-node-to-workspace t";
        };
        mode.service.binding = {
          cmd-ctrl-alt-comma = [ "reload-config" "mode main" ];
        };
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "/run/current-system/sw/bin/sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
        ];
        on-window-detected = [
          {
            "if" = {
              app-name-regex-substring = "emacs";
            };
            run = "move-node-to-workspace e";
          }
          {
            "if" = {
              app-id = "com.github.wez.wezterm";
            };
            run = "move-node-to-workspace t";
          }
          {
            "if" = {
              app-id = "com.tinyspeck.slackmacgap";
            };
            run = "move-node-to-workspace c";
          }
          {
            "if" = {
              app-id = "com.hnc.Discord";
            };
            run = "move-node-to-workspace c";
          }
          {
            "if" = {
              app-id = "org.whispersystems.signal-desktop";
            };
            run = "move-node-to-workspace c";
          }
        ];
      };
    };
    postgresql = {
      # enable = true;
      # package = pkgs.postgresql_16;
      # enableTCPIP = true;
      # dataDir = "/usr/local/var/postgres";
      # authentication = pkgs.lib.mkOverride 16 ''
      #   local all all trust
      #   host all all 127.0.0.1/32 trust
      #    host all all ::1/128 trust
      # '';
    };
    tailscale.enable = true;
    sketchybar = { enable = true; };
  };

  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs;
    [
      _1password-cli
      bat
      curl
      discord
      eza
      git
      lldb_19
      (pkgs.callPackage ./packages/pngpaste.nix {
        darwin = darwin;
      })
      # man-pages
      # man-pages-posix
      nixos-rebuild
      nushell
      aerospace
      ripgrep
      wezterm
      wget
      zellij
      nodePackages."prettier"
      (pkgs.writeScriptBin "rebuild-darwin"
        ''
          sudo darwin-rebuild switch --flake ~/dotfiles/home-manager
        '')
    ];

  networking = {
    hostName = "heimdall";
    computerName = "heimdall";
  };
  # So we also use homebrew for GUI packages we want to launch through spotlight/raycast
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    taps = [
      "homebrew/bundle"
      "homebrew/services"
      "mediosz/tap"
    ];
    # Unfortunately we need to create the postgres superuser ourselves
    # `CREATE USER postgres SUPERUSER;`
    brews = [
      "rubyfmt"
      {
        name = "postgresql@16";
        link = true;
        start_service = true;
      }
    ];
    casks = [
      "swipeaerospace"
      "hyperkey"
      "raycast"
      "vlc"
      "kap"
      "istat-menus"
      "keycastr"
      "docker-desktop"
    ];
  };

  environment.darwinConfig = "$HOME/dotfiles/home-manager";
  environment.shells = [ pkgs.nushell pkgs.zsh pkgs.bashInteractive ];

  # https://github.com/nix-community/home-manager/issues/423
  programs.nix-index.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
    nerd-fonts.hack
    sketchybar-app-font
    yanone-kaffeesatz
    powerline-fonts
    paratype-pt-mono
  ];

  # Darwin System configuration
  system = {
    primaryUser = "justin";
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;
    defaults = {
      dock = {
        autohide = true;
        orientation = "bottom";
        show-recents = false;
        launchanim = true;
      };
      smb.NetBIOSName = "heimdall";
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
  security.pam.services.sudo_local.touchIdAuth = true;
  system.stateVersion = 5;
}
