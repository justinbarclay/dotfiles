# Stolen from https://github.com/LnL7/nix-darwin/issues/339#issuecomment-1140352696
{ config, lib, pkgs, ... }:
with lib; {
  options.modules.darwin.postgres = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf config.modules.darwin.postgres.enable
    {
      users.users = { };
      services = {
        postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          dataDir = "/usr/local/var/postgres/data/";
          initdbArgs = [ "--locale" "en_CA.UTF-8" "--encoding" "UTF-8" "-D" "/usr/local/var/postgres/data" ];
        };
      };

      # Create the PostgreSQL data directory, if it does not exist.
      system.activationScripts.preActivation = {
        enable = true;
        text = ''
          if [ ! -d "/usr/local/var/postgres/data" ]; then
            echo "creating PostgreSQL data directory..."
            sudo mkdir -m 750 -p /usr/local/var/postgres/data/
            echo "16" > /usr/local/var/postgres/data/PG_VERSION
            su - postgres -c "initdb --locale en_CA.UTF-8 --encoding UTF-8 -D /usr/local/var/postgres/data"
            chown -R justin:staff /usr/local/var/postgres/data/
          fi
        '';
      };

      # Create a superuser matching the login user after postgres starts.
      launchd.daemons.postgresql.serviceConfig.KeepAlive = true;
      system.activationScripts.postActivation.text = ''
        if /usr/local/var/postgres/data/postmaster.pid 2>/dev/null; then
          psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${config.modules.darwin.postgres.user}'" \
            | grep -q 1 || psql -U postgres -c "CREATE USER ${config.modules.darwin.postgres.user} SUPERUSER;"
        fi
      '';


      # Direct log output for debugging.
      launchd.user.agents.postgresql.serviceConfig = {
        StandardErrorPath = "/Users/postgres/Library/Application Support/Postgresql/postgres.error.log";
        StandardOutPath = "/Users/postgres/Library/Application Support/Postgresql/postgres.out.log";
      };
    };
}
