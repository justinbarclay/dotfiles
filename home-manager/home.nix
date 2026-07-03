{ config, pkgs, user, system, ... }:
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
    ./llm.nix
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
    start-pueue = true;
  };
  modules.emacs = {
    enable = true;
    with-gtk = stdenv.isLinux;
  };

  modules.gtk.enable = stdenv.isLinux;

  programs = {
    home-manager.enable = true;
  };

  # Store GC is owned by the system config (Determinate's background collector),
  # so the user config no longer runs its own nix-collect-garbage agent.

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
      nixd
      act
      # Tools
      gnuplot
      graphviz
      zip
      bottom
      difftastic
      tealdeer
      hyperfine
      nodejs_24
      pandoc
      multimarkdown

      texliveFull
      mkcert
      typescript-language-server

      # eslint_d
      # ollama
      tidal.packages.${system}.default
      tidalkms

      (pkgs.writeScriptBin "rebuild-home" (builtins.readFile ./scripts/rebuild-home))
      (pkgs.writeScriptBin "scan-ruby" (builtins.readFile ./scripts/scan_ruby.nu))
      (pkgs.writeScriptBin "update-skills" ''
        #!/usr/bin/env bash
        exec ${pkgs.nushell}/bin/nu ${config.home.homeDirectory}/dotfiles/home-manager/modules/agentic-skills/update-skills.nu "$@"
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
      "26.11"; # To figure this out you can comment out the line and see what version it expected.
  };
}
