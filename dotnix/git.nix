{ config, lib, pkgs, ... }:

with lib; {
  options.modules.git = {
    enable = mkOption {
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
    home.file.".gitignore" = {
      executable = false;
      text = ''
        **/**/shell.nix
        **/**/.envrc
      '';
    };

    home.file.".gitconfig" = {
      executable = false;
      text = ''
        [user]
          email = github@justinbarclay.ca
          name = Justin Barclay
        [color]
          ui = true
        [core]
          editor = emacs
          excludesfile = ~/.gitignore
          editor = emacs
        [pull]
          rebase = true
        # [commit]
        #   gpgSign = true
        # [tag]
        #   gpgSign = true
      '';
    };
  };
}
