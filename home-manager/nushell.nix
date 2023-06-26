{ config, lib, pkgs, ... }:

with lib; {
  options.modules.nushell = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.nushell.enable {
    home.packages = with pkgs;
      [ nushell starship nix-direnv pueue atuin zoxide carapace fzf tidal-aws-full ];

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
        inline_height = 20;
        search_mode = "skim";
      };
    };

    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.nushell = {
      enable = true;
      configFile.source = ./config.nu;
      envFile.source = ./env.nu;
      shellAliases =
        {
          ssh = "ssh.exe";
          ssh-add = "ssh-add.exe";
          cat = "bat";
          ls = "ls";
          emacsBg = "pueue add -- emacs";
        };
    };

    services.pueue = {
      enable = true;
      settings = {
        client = {
          restart_in_place = false;
          read_local_logs = true;
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
    home.file.".npmrc" = {
      executable = false;
      text = ''
        prefix = \$\{HOME\}/.npm-packages
      '';
    };
  };
}
