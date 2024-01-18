{ config, lib, pkgs, ... }:

with lib; {
  options.modules.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    is-darwin = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.git.enable {
    home.packages = with pkgs; [
      git
      # Needed to sign commits
      gnupg
    ];

    programs.git.enable = true;
    home.file.".gitignore" = {
      executable = false;
      text = ''
        **/**/shell.nix
        **/**/.envrc
        **/**/.direnv/
      '';
    };

    home.file.".gitconfig" = {
      executable = false;
      source =
        if config.modules.git.is-darwin then
          ./config/.gitconfig-darwin else
          ./config/.gitconfig-wsl;

    };
    home.file.".allowed-signers" = {
      executable = false;
      text = ''
        # This file contains a list of allowed signers for git commits.
        # It is used by the git hooks to verify that commits are signed by
        # a trusted key.
        #
        # The format is one key per line, with the key ID followed by a space
        # and the key fingerprint.
        #
        # Example:
        # 1234567890ABCDEF 1234567890ABCDEF1234567890ABCDEF12345678
        git@justinbarclay.ca ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbygxEvFlS66vaugGRlbXRO4yjozS8G+yYrKh9lmZo
      '';
    };
  };
}
