{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, emacs-overlay, ... }:
    let
      system = "x86_64-linux";
      user = "justin";
      emacs-overlay = import (builtins.fetchTarball {
        url =
          "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz?rev=d561db310f51e8bd705d53058f08c6ae7ed3d23b";
        sha256 = "0lhywzmm09v1jrbgv5k04ds2li4nrbbd5hkmmx9cs6zcfq9xy3iq";
      });
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ emacs-overlay ];
      };
      lib = nixpkgs.lib;
    in {
      defaultPackage.${system} = home-manager.defaultPackage.${system};

      homeConfigurations = {
        ${user} = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit user;  };
          modules = [ ./home.nix ];
        };
      };
    };
}
