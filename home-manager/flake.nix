{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      url = "git+ssh://git@github.com/tidalmigrations/tidal-tools?ref=jb/flake-update";
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
    }@inputs:
    let
      user = "justin";

      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "33a166b214c841d6fa5874ccc925871b2394a7e3"; # change the revision
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
