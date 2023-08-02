# Stolen from https://github.com/LnL7/nix-darwin/issues/339#issuecomment-1140352696
{ config, lib, pkgs, ... }:
with lib; {
  options.modules.darwin.redis = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    bind = mkOption {
      type = types.str;
      default = "localhost";
    };
  };

  config = mkIf config.modules.darwin.redis.enable

    {
      services = {
        redis = {
          enable = true;
          bind = config.modules.darwin.redis.bind;
          dataDir = "/var/lib/redis/";
        };
      };

      # Create the Redis data directory, if it does not exist.
      system.activationScripts.preActivation = {
        enable = true;
        text = ''
          if [ ! -d "/var/lib/redis" ];
            then
            echo "creating Redis data directory..."
            sudo mkdir -m 750 -p /var/lib/redis
            chown -R justin:staff /var/lib/redis
          fi
        '';
      };


      # Direct log output for debugging.
      launchd.user.agents.postgresql.serviceConfig = {
        StandardErrorPath = "/Users/postgres/Library/Application Support/Redis/redis.error.log";
        StandardOutPath = "/Users/postgres/Library/Application Support/Redis/redis.out.log";
      };
    };
}
