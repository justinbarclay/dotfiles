{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    devenv.url = "github:cachix/devenv/latest";
    tidal-overlay = {
      url = "git+ssh://git@github.com/tidalmigrations/aws-sso";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tidal-tools = {
      url = "git+ssh://git@github.com/tidalmigrations/tidal-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , emacs-overlay
    , home-manager
    , tidal-overlay
    , nixos-wsl
    , nix-darwin
    , flake-utils
    , tidal-tools
    , ...
    }:
    let
      user = "justin";

      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "2d35141c7cfac4d784498427f3ad6f28bf980c3d";
      });

      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration
        {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
            overlays = [
              (final: prev:
                {
                  tidal = tidal-tools;
                })
              emacs-overlay
              tidal-overlay.overlays.default
            ];
          };
          extraSpecialArgs = {
            inherit system;
            inherit user;
          };
          modules = [ ./home.nix ];
        };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations."vider" = lib.nixosSystem
        {
          system = "x86_64-linux";
          modules = [ nixos-wsl.nixosModules.wsl ./wsl.nix ];
        };

      darwinConfigurations."heimdall" = nix-darwin.lib.darwinSystem
        {
          system = "aarch64-darwin";
          modules = [
            ./darwin.nix
          ];
        };
      homeConfigurations."justin@nixos" = mkHomeConfig "x86_64-linux";
      homeConfigurations."justin@heimdall" = mkHomeConfig "aarch64-darwin";
    };
}
