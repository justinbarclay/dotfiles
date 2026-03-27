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
      users.knownUsers = [ "postgres" ];
      users.users.postgres = {
        uid = 70;
        gid = 70;
        home = "/var/lib/postgresql";
        createHome = true;
        shell = "/bin/sh";
        description = "PostgreSQL server account";
      };

      users.knownGroups = [ "postgres" ];
      users.groups.postgres = {
        gid = 70;
        description = "PostgreSQL server group";
      };

      services = {
        postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          dataDir = "/usr/local/var/postgres/data/";
          initdbArgs = [ "--locale" "en_CA.UTF-8" "--encoding" "UTF-8" "-D" "/usr/local/var/postgres/data" ];
        };
      };

      # Create the PostgreSQL data directory and initialise it as the postgres user.
      system.activationScripts.preActivation = {
        enable = true;
        text = ''
          if [ ! -d "/usr/local/var/postgres/data" ]; then
            echo "creating PostgreSQL data directory..."
            mkdir -m 750 -p /usr/local/var/postgres/data/
            chown postgres:postgres /usr/local/var/postgres/data/
            su - postgres -c "${pkgs.postgresql_16}/bin/initdb --locale en_CA.UTF-8 --encoding UTF-8 -D /usr/local/var/postgres/data"
          fi
        '';
      };

      # Create a superuser matching the login user after postgres starts.
      launchd.daemons.postgresql.serviceConfig.KeepAlive = true;
      system.activationScripts.postActivation.text = ''
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
        StandardErrorPath = "/var/lib/postgresql/postgres.error.log";
        StandardOutPath = "/var/lib/postgresql/postgres.out.log";
      };
    };
}
