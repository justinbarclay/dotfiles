{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, emacs-overlay, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      user = "justin";
      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "f03b172233e1bf1fb2ffbc543b86aae00fbad444"; # change the revision
      });
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ emacs-overlay ];
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations."vider" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ /etc/nixos/configuration.nix ./wsl.nix ];
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
