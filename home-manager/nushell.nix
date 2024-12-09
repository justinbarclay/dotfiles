{ config, system, lib, pkgs, ... }:

with lib; {
  options.modules.nushell = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    start-pueue = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.nushell.enable {
    home.packages = with pkgs;
      [
        nushell
        starship
        nix-direnv
        atuin
        zoxide
        carapace
        fzf
        tidal-aws-full
        tidal
      ];

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.atuin = {
      enable = true;
      enableNushellIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        auto_sync = true;
        workspaces = true;
        sync_frequency = "1h";
        search_mode = "skim";
      };
    };

    home.file.".config/starship.toml" = {
      executable = false;
      enable = true;
      source = ./config/starship.toml;
    };

    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.nushell = {
      enable = true;
      configFile.source = ./config/config.nu;
      envFile.source = ./config/env.nu;
      shellAliases =
        {
          cat = "bat";
          ls = "ls";
          emacsBg = "pueue add -- emacs";
        } //
        (if pkgs.stdenv.isLinux then
          {
            ssh = "ssh.exe";
            ssh-add = "ssh-add.exe";
          }
        else
          { });

      extraEnv = ''
        $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | append ${pkgs.tidal-aws-full}/share/tidal-aws)
      '';
      extraConfig = ''
        use tidal-aws.nu
      '';
    };

    services = mkIf config.modules.nushell.start-pueue {
      pueue = {
        enable = true;
        settings = {
          client = {
            restart_in_place = false;
            read_local_logs = true;
            default_parallel_tasks = 2;
            show_confirmation_questions = false;
            show_expanded_aliases = false;
            dark_mode = false;
            max_status_lines = null;
            status_time_format = "%H:%M:%S";
            status_datetime_format = "%Y-%m-%d\n%H:%M:%S";
          };
          daemon = {
            pause_group_on_failure = false;
            pause_all_on_failure = false;
            callback = null;
            callback_log_lines = 10;
          };
          shared = {
            pueue_directory = null;
            runtime_directory = null;
            use_unix_socket = false;
            pid_path = null;
            unix_socket_path = null;
            host = "127.0.0.1";
            port = "6924";
            daemon_cert = null;
            daemon_key = null;
            shared_secret_path = null;
          };
        };
      };
    };
  };
}
