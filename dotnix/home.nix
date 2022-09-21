{ config, lib, pkgs, user, ... }: {
  imports = [ ./git.nix ./zsh.nix ./emacs.nix ];
  modules.git.enable = true;
  modules.zsh.enable = true;
  modules.emacs.enable = true;

  programs.home-manager.enable = true;
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      nixfmt
      cowsay
      gnupg
      # Basic shell setup
      openssh
      # Dev Niceness
      postgresql
      # Tools
      gnuplot
      graphviz
      zip
      htop
      pkgs.nodePackages."prettier"
    ];
    stateVersion =
      "22.05"; # To figure this out you can comment out the line and see what version it expected.
  };
}
