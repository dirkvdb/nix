{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant = {
      url = "github:abenz1267/elephant";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      elephant,
      walker,
    }:
    {
      nixosConfigurations.mini =
        let
          userConfig = {
            hostname = "mini";
            username = "dirk";
          };
        in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs userConfig elephant walker;};
          modules = [
            ./hosts/minisforum-ai-x1/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.dirk = import ./home/linux.nix;
                extraSpecialArgs = { inherit userConfig elephant walker; system = "x86_64-linux"; };
              };
            }
          ];
        };

      # Build darwin flake using:
      # darwin-rebuild build --flake ~/.config/nix/#MacBook-Pro
      # sudo darwin-rebuild switch --flake ~/.config/nix/#MacBook-Pro
      darwinConfigurations."MacBook-Pro" =
        let
          userConfig = {
            hostname = "macbook-pro";
            username = "dirk";
          };
        in
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./modules/darwin/system.nix
            ./modules/darwin/applications.nix

            home-manager.darwinModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.dirk = import ./home/darwin.nix;
                extraSpecialArgs = { inherit userConfig; };
              };
            }
          ];
          specialArgs = {
            inherit inputs userConfig;
          };
        };
      };
}
