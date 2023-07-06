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
  };

  outputs = { self, nixpkgs, emacs-overlay, home-manager, tidal-overlay, nixos-wsl, ... }@inputs:
    let
      system = "x86_64-linux";
      user = "justin";
      # tidal-overlay = builtins.getFlake "git+ssh://git@github.com/tidalmigrations/aws-sso?ref=jb/nushell";
      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "f03b172233e1bf1fb2ffbc543b86aae00fbad444"; # change the revision
      });
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          emacs-overlay
          tidal-overlay.overlays.default
        ];
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations."vider" = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ nixos-wsl.nixosModules.wsl ./wsl.nix ];
      };

      defaultPackage.${system} = home-manager.defaultPackage.${system};

      homeConfigurations = {
        ${user} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit user; };
          modules = [ ./home.nix ];
        };
      };
    };
}
