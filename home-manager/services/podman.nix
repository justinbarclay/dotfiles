{ config, lib, user, ... }:
with lib; {
  options.modules.darwin.podman = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  # NOTE: this relies on the Homebrew podman installation (the `podman-desktop` cask in
  # darwin.nix, which puts the binaries and the vfkit/gvproxy helpers in /opt/podman/bin).
  # It does not use nixpkgs' podman. Nix only manages starting the VM at login, so the
  # MCP servers that shell out to podman work.
  config = mkIf config.modules.darwin.podman.enable {
    launchd.user.agents.podman-machine = {
      serviceConfig = {
        RunAtLoad = true;
        ProgramArguments = [ "/opt/podman/bin/podman" "machine" "start" ];
        # `machine start` returns once the VM is up, leaving vfkit/gvproxy running as
        # children. Without this launchd kills them when the job exits.
        AbandonProcessGroup = true;
        StandardOutPath = "/Users/${user}/.podman-machine.log";
        StandardErrorPath = "/Users/${user}/.podman-machine.log";
        EnvironmentVariables = {
          PATH = "/opt/podman/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          HOME = "/Users/${user}";
        };
      };
    };
  };
}
