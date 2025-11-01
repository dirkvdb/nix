{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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

  };

  outputs =
    {
      self,
      nixpkgs,
      nix-index-database,
      nixos-hardware,
      darwin,
      home-manager,
      elephant,
      walker,
      zen-browser,
    }@inputs:
    let
      # Custom packages overlay
      overlay = final: prev: {
        plymouth-theme-nixos = prev.callPackage ./pkgs/plymouth-theme-nixos { };
      };
    in
    {
      nixosConfigurations.mini =
        let
          system = "x86_64-linux";
          userConfig = {
            hostname = "mini";
            username = "dirk";
            theme = "everforest";
            qtScaleFactor = 2;
          };
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              inputs
              system
              userConfig
              ;
          };
          modules = [
            ./hosts/minisforum-ai-x1/configuration.nix
            nix-index-database.nixosModules.nix-index

            {
              nixpkgs.overlays = [ overlay ];
            }
          ];
        };

      # Build darwin flake using:
      # darwin-rebuild build --flake ~/.config/nix/#MacBook-Pro
      # sudo darwin-rebuild switch --flake ~/.config/nix/#MacBook-Pro
      darwinConfigurations."macbook-pro" =
        let
          system = "aarch64-darwin";
          userConfig = {
            hostname = "macbook-pro";
            username = "dirk";
          };
        in
        darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              inputs
              system
              userConfig
              ;
          };
          modules = [
            ./hosts/macbook-pro-m2/configuration.nix
            nix-index-database.darwinModules.nix-index

            {
              nixpkgs.overlays = [ overlay ];
            }
          ];
        };
    };
}
