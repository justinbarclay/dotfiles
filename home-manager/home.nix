{ config, lib, pkgs, user, system, ... }:
let
  stdenv = pkgs.stdenv;
in
{
  imports = [
    ./git.nix
    ./zsh.nix
    ./emacs.nix
    ./nushell.nix
    ./gtk.nix
    ./email.nix
  ];
  modules.git = {
    is-darwin = stdenv.isDarwin;
    enable = true;
  };

  modules.zsh.enable = false;
  modules.email = {
    enable = true;
  };
  modules.nushell = {
    enable = true;
    start-pueue = stdenv.isLinux;
  };
  modules.emacs = {
    enable = true;
    with-gtk = stdenv.isLinux;
  };

  modules.gtk.enable = stdenv.isLinux;

  programs = {
    home-manager.enable = true;
  };

  nix.gc = {
    automatic = true;
    persistent = true;
  };
  home = {
    username = "${user}";
    language.base = "en_CA.UTF-8";
    homeDirectory =
      if stdenv.isDarwin then "/Users/${user}" else "/home/${user}";

    packages = with pkgs; [
      nixpkgs-fmt
      cowsay
      gnupg
      cachix
      nil
      # Basic shell setup
      openssh
      act

      #virtualisation
      podman

      # Tools
      gnuplot
      graphviz
      zip
      bottom
      nodejs
      pandoc
      android-tools
      texlive.combined.scheme-full
      mkcert
      pkgs.nodePackages."prettier"
      pkgs.nodePackages."typescript-language-server"
      eslint_d
      (pkgs.writeScriptBin "nix-update"
        ''
          cd ~/.config/home-manager

          case $(uname) in
            Linux)
              op.exe inject -i email.tpl.nix -o email.nix
              ;;
            Darwin)
              op inject -i email.tpl.nix -o email.nix
              ;;
            '*')
              echo Hi, stranger!
              ;;
          esac
          export NIXPKGS_ALLOW_BROKEN=1;

          nix flake update
          home-manager switch

          shred -u ./email.nix
        '')
    ];

    file.".npmrc" = {
      executable = false;
      text = ''
        prefix = \$\{HOME\}/.npm-packages
      '';
    };
    file.".wezterm.lua" = {
      executable = false;
      source = ./config/.wezterm.lua;
    };

    stateVersion =
      "22.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
