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
      text = ''
        [user]
          email = git@justinbarclay.ca
          name = Justin Barclay
          signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbygxEvFlS66vaugGRlbXRO4yjozS8G+yYrKh9lmZo
        [color]
          ui = true
        [core]
          editor = emacs
          excludesfile = ~/.gitignore
          sshCommand = ssh.exe
        [init]
          defaultBranch = main
        [pull]
          rebase = true
        [gpg]
          format = ssh
        [gpg "ssh"]
          program = op-ssh-sign.exe
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
