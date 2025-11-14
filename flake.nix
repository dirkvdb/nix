{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # prebuilt database for nix-index (find packages for missing binaries)
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant = {
      url = "github:abenz1267/elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      nixpkgs,
      nix-index-database,
      nixos-wsl,
      darwin,
      ...
    }@inputs:
    let
      # Custom packages overlay
      overlay = final: prev: {
        plymouth-theme-nixos = prev.callPackage ./pkgs/plymouth-theme-nixos { };
      };

      # Helper function for NixOS configurations
      mkNixos =
        {
          system,
          hostPath,
          extraModules ? [ ],
          extraOverlays ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs system;
          };
          modules = [
            hostPath
            nix-index-database.nixosModules.nix-index
            { nixpkgs.overlays = [ overlay ] ++ extraOverlays; }
          ]
          ++ extraModules;
        };

      # Helper function for Darwin configurations
      mkDarwin =
        {
          system,
          hostPath,
          extraOverlays ? [ ],
        }:
        darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs system;
          };
          modules = [
            hostPath
            nix-index-database.darwinModules.nix-index
            { nixpkgs.overlays = [ overlay ] ++ extraOverlays; }
          ];
        };
    in
    {
      nixosConfigurations = {
        mini = mkNixos {
          system = "x86_64-linux";
          hostPath = ./hosts/minisforum-ai-x1/configuration.nix;
        };

        macbook-pro = mkNixos {
          system = "aarch64-linux";
          hostPath = ./hosts/macbook-pro-m2-nixos/configuration.nix;
          extraOverlays = [ inputs.apple-silicon.overlays.apple-silicon-overlay ];
        };

        wsl = mkNixos {
          system = "x86_64-linux";
          hostPath = ./hosts/wsl/configuration.nix;
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      };

      darwinConfigurations."macbook-pro" = mkDarwin {
        system = "aarch64-darwin";
        hostPath = ./hosts/macbook-pro-m2/configuration.nix;
      };
    };
}
