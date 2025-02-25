{ config, lib, pkgs, ... }:

with lib; {
  options.modules.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.zsh.enable {
    home.packages = with pkgs; [ zsh zinit starship nix-direnv ];
    # services.lorri.enable = true;
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.starship.enable = true;

    programs.zsh = {
      # Disable this for now, it tries to take control zshrc but this
      # is controlled in my dotfiles for now
      enable = true;

      autocd = true;
      enableCompletion = true;
      enableAutosuggestions = true;

      initExtraFirst = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
      '';
      shellAliases =
        {
          ssh = "ssh.exe";
          ssh-add = "ssh-add.exe";
        };
    };
    home.file.".npmrc" = {
      executable = false;
      text = ''
        prefix = \$\{HOME\}/.npm-packages
      '';
    };
  };
}
