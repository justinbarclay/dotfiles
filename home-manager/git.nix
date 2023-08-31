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
      '';
    };

    home.file.".gitconfig" = {
      executable = false;
      source =
        if config.modules.git.is-darwin then
          ./.gitconfig-darwin else
          ./.gitconfig-wsl;

    };
  };
}
