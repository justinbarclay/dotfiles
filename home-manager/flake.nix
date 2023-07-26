{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs";
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
    , ...
    }@inputs:
    let
      user = "justin";

      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "f03b172233e1bf1fb2ffbc543b86aae00fbad444"; # change the revision
      });

      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration
        {
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
            overlays = [
              emacs-overlay
              tidal-overlay.overlays.default
            ];
          };
          extraSpecialArgs = {
            system = "aarch64-darwin";
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

      darwinConfigurations."Heimdall" = nix-darwin.lib.darwinSystem
        {
          system = "aarch64-darwin";
          modules = [
            ./darwin.nix
          ];
        };
      packages."x86_64-linux".homeConfigurations."justin" = mkHomeConfig "x86_64-linux";
      packages."aarch64-darwin".homeConfigurations."justin" = mkHomeConfig "aarch64-darwin";
    };
}
