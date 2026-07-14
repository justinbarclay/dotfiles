{
  description = "My Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
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
    emacs-lsp-booster = {
      url = "github:slotThe/emacs-lsp-booster-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tidalkms = {
      url = "git+ssh://git@github.com/tidalmigrations/tidalkms";
    };
    emacs-overlay = {
      # Pinned to a known-good rev; emacs-overlay master occasionally breaks.
      # Bump deliberately with: nix flake update emacs-overlay
      url = "github:nix-community/emacs-overlay/9bae184ed0c04cf270fbb0c9ba886d49bc9cc5e2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , nixpkgs-stable
    , home-manager
    , tidal-overlay
    , nixos-wsl
    , nix-darwin
    , tidal-tools
    , emacs-lsp-booster
    , determinate
    , tidalkms
    , emacs-overlay
    , ...
    }:
    let
      user = "justin";
      lib = nixpkgs.lib;

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
                  direnv = (import nixpkgs-stable { inherit system; }).direnv;
                  stable = import nixpkgs-stable {
                    inherit system;
                    config = {
                      allowUnfree = true;
                    };
                  };
                })
              emacs-overlay.overlays.default
              tidal-overlay.overlays.default
              tidalkms.overlays.default
              emacs-lsp-booster.overlays.default
            ];
          };
          extraSpecialArgs = {
            inherit system;
            inherit user;
          };
          modules = [ ./home.nix ];
        };
    in
    {
      nixosConfigurations."vider" = lib.nixosSystem
        {
          system = "x86_64-linux";
          specialArgs = { inherit user; };
          modules = [ nixos-wsl.nixosModules.wsl ./wsl.nix ];
        };

      darwinConfigurations."heimdall" = nix-darwin.lib.darwinSystem
        {
          system = "aarch64-darwin";
          specialArgs = { inherit user; };
          modules = [
            determinate.darwinModules.default
            ./darwin.nix
          ];
        };
      homeConfigurations."justin@nixos" = mkHomeConfig "x86_64-linux";
      homeConfigurations."justin@heimdall" = mkHomeConfig "aarch64-darwin";
    };
}
