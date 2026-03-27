{ config, lib, pkgs, ... }:
with lib; {
  options.modules.darwin.pueue = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.darwin.pueue.enable

    {
      environment.systemPackages = with pkgs; [
        pueue
      ];

      # Direct log output for debugging.
      launchd.user.agents.pueued = {
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          Program = "${pkgs.pueue}/bin/pueued";
          ProgramArguments = [ "-vv" ];
          WorkingDirectory = "/Users/justin";
          StandardOutPath = "/Users/justin/.pueue.stdout.log";
          StandardErrorPath = "/Users/justin/.pueue.stderr.log";
          EnvironmentVariables = {
            PATH = "/etc/profiles/per-user/justin/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            HOME = "/Users/justin";
            SHELL = "/run/current-system/sw/bin/nu";
          };
          ProcessType = "Interactive";
        };
      };
    };
}
