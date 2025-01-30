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
    username = builtins.getEnv "fastmailUsername";
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
      act

      #virtualisation
      podman

      # Tools
      gnuplot
      graphviz
      zip
      bottom
      nodejs_22
      pandoc
      android-tools
      texlive.combined.scheme-full
      mkcert
      nodePackages."prettier"
      nodePackages."typescript-language-server"
      nodePackages."typescript"

      eslint_d
      ollama
      (pkgs.writeScriptBin "nix-update"
        ''
          cd ~/.config/home-manager
          export NIXPKGS_ALLOW_BROKEN=1;

          nix flake update

          case $(uname) in
            Linux)
              OP_COMMAND="op.exe read"
              ;;
            Darwin)
              OP_COMMAND="op read"
              ;;
            '*')
              echo Hi, stranger!
              ;;
          esac

          export fastmailUsername=$($OP_COMMAND op://Private/fastmail-smtp/username)
          # Allow environment variables to be read for fastmail username
          home-manager switch --impure
        '')
    ];

    file.".npmrc" = {
      executable = false;
      text = ''
        prefix = ~/.npm-packages
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
