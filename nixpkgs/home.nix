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
    language.base = "en_US.UTF-8";
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      nixpkgs-fmt
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
      pandoc
      texlive.combined.scheme-medium

      pkgs.nodePackages."prettier"
      pkgs.nodePackages."typescript-language-server"
    ];
    stateVersion =
      "22.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
