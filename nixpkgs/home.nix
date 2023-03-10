{ config, lib, pkgs, user, ... }: {
  imports = [ ./git.nix ./zsh.nix ./emacs.nix ];
  modules.git.enable = true;
  modules.zsh.enable = true;
  modules.emacs.enable = true;
  programs.home-manager.enable = true;
  gtk = {
    enable = true;
    theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };
  };
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      nixfmt
      cowsay
      gnupg
      # Basic shell setup
      wl-clipboard-x11
      openssh
      # Dev Niceness
      postgresql
      # Tools
      gnuplot
      graphviz
      zip
      htop
      nodejs
      pkgs.nodePackages."prettier"
      pkgs.nodePackages."typescript-language-server"
    ];
    stateVersion =
      "22.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
