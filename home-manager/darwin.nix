{ pkgs, lib, user, ... }:
{
  imports = [ ./services/redis.nix ./services/pueue.nix ./services/mbsync.nix ./services/postgres.nix ];

  modules.darwin.postgres = {
    enable = false;
    user = user;
  };

  modules.darwin.pueue = {
    enable = true;
  };
  modules.darwin.redis = {
    enable = true;
  };
  modules.darwin.mbsync = {
    enable = true;
    postExec = ''
      ${pkgs.mu}/bin/mu index
      NEW_COUNT=$(${pkgs.mu}/bin/mu find flag:new 2>/dev/null | wc -l | tr -d ' ')
      if [ "$NEW_COUNT" -gt 0 ]; then
        /usr/bin/osascript -e "display notification \"$NEW_COUNT new email(s)\" with title \"📬 New Mail\""
      fi
    '';
  };
  # Nix configuration ------------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  users.users = {
    "${user}" = {
      name = user;
      shell = pkgs.nushell;
      home = "/Users/${user}";
    };
  };

  ids.gids.nixbld = 30000;

  determinateNix = {
    enable = true;
    nixosVmBasedLinuxBuilder = {
      enable = true;
    };
  };
  nix = {
    # use determinate nix to manage nix
    enable = false;
    linux-builder = {
      enable = false;
      ephemeral = true;
      maxJobs = 4;
      config = {
        # virtualisation = {
        #   darwin-builder = {
        #     diskSize = 40 * 1024;
        #     memorySize = 8 * 1024;
        #   };
        #   cores = 6;
        # };
      };
    };
    extraOptions = ''
      extra-nix-path = nixpkgs=flake:nixpkgs
      bash-prompt-prefix = (nix:$name)
      experimental-features = nix-command flakes auto-allocate-uids
    '';
    settings = {
      trusted-users = [ "root" user "@admin" ];
      extra-trusted-users = user;
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
            "if" = { app-name-regex-substring = ".*"; };
            run = [ "exec-and-forget /run/current-system/sw/bin/sketchybar --trigger aerospace_workspace_change" ];
          }
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
      nodejs_25
      prettier
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
      "mediosz/tap"
    ];
    brews = [
      "rubyfmt"
      {
        name = "postgresql@18";
        restart_service = "changed";
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
      "podman-desktop"
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
    primaryUser = user;
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToControl = true;
    defaults = {
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        AppleKeyboardUIMode = 3;
        NSAutomaticWindowAnimationsEnabled = false;
      };
      dock = {
        autohide = true;
        orientation = "bottom";
        show-recents = false;
        launchanim = true;
        mru-spaces = false;
      };
      smb.NetBIOSName = "heimdall";
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowPathbar = true;
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
