{ config, lib, pkgs, user, system ? <system>, ... }: {
  imports = [ ./git.nix ./zsh.nix ./emacs.nix ./nushell.nix ./gtk.nix ];
  modules.git.enable = true;
  modules.zsh.enable = false;
  modules.nushell.enable = true;
  modules.emacs.enable = true;
  modules.gtk.enable = system == "x86_64-linux";
  programs.home-manager.enable = true;

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
      eslint_d
    ];
    stateVersion =
      "22.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
