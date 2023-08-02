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
      launchd.user.agents.pueue = {
        serviceConfig = {
          KeepAlive = true;
          Program = "${pkgs.pueue}/bin/pueued";
          ProgramArguments = [ "--verbose" ];
          StandardErrorPath = "/Users/justin/Library/Application Support/Pueue/pueue.error.log";
          StandardOutPath = "/Users/justin/Library/Application Support/Pueue/pueue.out.log";
        };
      };
    };
}
