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
          email = git@justinbarclay.ca
          name = Justin Barclay
          signingkey = 513F198C40AEC0C2
        [color]
          ui = true
        [core]
          editor = emacs
          excludesfile = ~/.gitignore
        [init]
          defaultBranch = main
        [pull]
          rebase = true
        [gpg]
          program = /home/justin/.nix-profile/bin/gpg2
        [commit]
          gpgSign = true
        [tag]
          gpgSign = true
        [github]
          user = justinbarclay
      '';
    };
  };
}
