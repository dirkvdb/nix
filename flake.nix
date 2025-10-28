{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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
      nixos-hardware,
      darwin,
      home-manager,
      elephant,
      walker,
      zen-browser,
    }@inputs:
    {
      nixosConfigurations.mini =
        let
          system = "x86_64-linux";
          userConfig = {
            hostname = "mini";
            username = "dirk";
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              userConfig
              elephant
              walker
              ;
          };
          modules = [
            {
              _module.args = { inherit userConfig; };
              imports = [ ./hosts/minisforum-ai-x1/configuration.nix ];
            }
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-cpu-amd-zenpower
            nixos-hardware.nixosModules.common-gpu-amd
            nixos-hardware.nixosModules.common-hidpi
            nixos-hardware.nixosModules.common-pc-ssd

            home-manager.nixosModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.dirk = import ./home/linux.nix;

                extraSpecialArgs = {
                  inherit
                    userConfig
                    elephant
                    walker
                    zen-browser
                    system
                    ;
                };
              };
            }
          ];
        };

      # Build darwin flake using:
      # darwin-rebuild build --flake ~/.config/nix/#MacBook-Pro
      # sudo darwin-rebuild switch --flake ~/.config/nix/#MacBook-Pro
      darwinConfigurations."MacBook-Pro" =
        let
          system = "aarch64-darwin";
          userConfig = {
            hostname = "macbook-pro";
            username = "dirk";
          };
        in
        darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/macbook-pro-m2/configuration.nix

            home-manager.darwinModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.dirk = import ./home/darwin.nix;
                extraSpecialArgs = {
                  inherit
                    userConfig
                    system
                    ;
                };
              };
            }
          ];
          specialArgs = {
            inherit
              inputs
              userConfig
              ;
          };
        };
    };
}
