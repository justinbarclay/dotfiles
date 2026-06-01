# Ollama service for Darwin
{ config, lib, pkgs, user, ... }:
with lib; {
  options.modules.darwin.ollama = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.darwin.ollama.enable {
    environment.systemPackages = [ pkgs.ollama ];

    launchd.user.agents.ollama = {
      serviceConfig = {
        ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/Users/${user}/.ollama.stdout.log";
        StandardErrorPath = "/Users/${user}/.ollama.stderr.log";
        EnvironmentVariables = {
          OLLAMA_HOST = "127.0.0.1:11434";
          HOME = "/Users/${user}";
        };
      };
    };
  };
}
