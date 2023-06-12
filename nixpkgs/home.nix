{ config, lib, pkgs, user, ... }: {
  imports = [ ./git.nix ./zsh.nix ./emacs.nix ./nushell.nix ];
  modules.git.enable = true;
  modules.zsh.enable = true;
  modules.nushell.enable = true;
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
    language.base = "en_CA.UTF-8";
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      nixpkgs-fmt
      cowsay
      gnupg
      cachix
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
      pandoc
      xdg-utils
      texlive.combined.scheme-medium

      pkgs.nodePackages."prettier"
      pkgs.nodePackages."typescript-language-server"
    ];
    stateVersion =
      "22.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
