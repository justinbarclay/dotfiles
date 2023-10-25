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
        };
      };
    };
}
