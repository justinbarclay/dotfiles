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
      user = "nixos";
      emacs-overlay = import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "d89c71d82edf170629279d731e0772feb5037f4c"; # change the revision
      });
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ emacs-overlay ];
      };
      lib = nixpkgs.lib;
    in {
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
