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
      services = {
        postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          dataDir = "/usr/local/var/postgres/data/";
          initdbArgs = [ "--locale" "en_CA.UTF-8" "--encoding" "UTF-8" "-D" "/usr/local/var/postgres/data" ];
        };
      };

      # Runs after user/group setup so the postgres OS user already exists.
      # Initialises the data directory on first run, then creates a superuser
      # matching the login user if postgres is already running.
      system.activationScripts.postActivation.text = ''
        if [ ! -d "/usr/local/var/postgres/data" ]; then
          echo "creating PostgreSQL data directory..."
          mkdir -p /usr/local/var/postgres/data/
          chmod 750 /usr/local/var/postgres/data/
          chown postgres:postgres /usr/local/var/postgres/data/
          su - postgres -c "${pkgs.postgresql_16}/bin/initdb --locale en_CA.UTF-8 --encoding UTF-8 -D /usr/local/var/postgres/data"
        fi
        if [ -f /usr/local/var/postgres/data/postmaster.pid ]; then
          ${pkgs.postgresql_16}/bin/psql -U postgres -tAc \
            "SELECT 1 FROM pg_roles WHERE rolname='${config.modules.darwin.postgres.user}'" \
            | grep -q 1 || \
            ${pkgs.postgresql_16}/bin/psql -U postgres \
              -c "CREATE USER ${config.modules.darwin.postgres.user} SUPERUSER;"
        fi
      '';

      # Direct log output for debugging.
      launchd.daemons.postgresql.serviceConfig = {
        KeepAlive = true;
        StandardErrorPath = "/var/lib/postgresql/postgres.error.log";
        StandardOutPath = "/var/lib/postgresql/postgres.out.log";
      };
    };
}
