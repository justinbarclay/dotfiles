{
  description = "Ruby on Rails development for Tidal";
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pg_version = "13";
        overlays = [ (self: super: { ruby = pkgs.ruby_2_7; }) ];
        pkgs = import nixpkgs { inherit overlays system; };

        rubyEnv = pkgs.bundlerEnv {
          # The full app environment with dependencies
          name = "rails-env";
          inherit (pkgs) ruby;
          gemdir = ./.; # Points to Gemfile.lock and gemset.nix
          gemConfig = pkgs.defaultGemConfig // {
            pg = attrs: {
              buildFlags = [
                "--with-pg-config=${
                  pkgs."postgresql_${pg_version}"
                }/bin/pg_config"
              ];
            };
          };
        };

        # updateDeps = pkgs.writeScriptBin "update-deps" (builtins.readFile
        #   (pkgs.substituteAll {
        #     src = ./scripts/update.sh;
        #     bundix = "${pkgs.bundix}/bin/bundix";
        #     bundler = "${rubyEnv.bundler}/bin/bundler";
        #   }));
      in {
        apps.default = {
          type = "app";
          program = "${rubyEnv}/bin/rails";
        };

        devShells = rec {
          default = run;

          run = pkgs.mkShell {
            buildInputs = [ rubyEnv rubyEnv.wrappedRuby pkgs.nodejs pkgs.postgresql_13 ];

            shellHook = ''
              ${rubyEnv}/bin/rails --version
            '';
          };
        };

        packages = {
          default = rubyEnv;

          docker = pkgs.dockerTools.buildImage {
            name = "rails-app";
            tag = "latest";
            fromImage = pkgs.dockerTools.pullImage {
              imageName = "ubuntu";
              finalImageTag = "20.04";
              imageDigest =
                "sha256:a06ae92523384c2cd182dcfe7f8b2bf09075062e937d5653d7d0db0375ad2221";
              sha256 = "sha256-d249m1ZqcV72jfEcHDUn+KuOCs8WPaBJRcZotJjVW0o=";
            };
            config.Cmd = [ "${rubyEnv}/bin/bundler" ];
          };
        };
      });
}
