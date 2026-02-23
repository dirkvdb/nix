{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # prebuilt database for nix-index (find packages for missing binaries)
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
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

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lan-mouse = {
      url = "github:feschber/lan-mouse";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-index-database,
      nixos-wsl,
      sops-nix,
      darwin,
      ...
    }@inputs:
    let
      # Custom packages overlay
      overlay = final: prev: {
        plymouth-theme-nixos = prev.callPackage ./pkgs/plymouth-theme-nixos { };
        color-lsp = prev.callPackage ./pkgs/color-lsp { };

        # Patch keepassxc to include NativeMessageInstaller.patch
        # This avoids error messages at startup that the browser connection files cannot be written
        # They are readonly because they are managed by the Nix config
        keepassxc = prev.keepassxc.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./modules/home/apps/keepassxc/NativeMessageInstaller.patch
          ];
        });
      };

      hpcSystem = "x86_64-linux";
      hpcOverlay = final: prev: {
        yazi = prev.yazi-unwrapped;
      };
      hpcPkgs = import nixpkgs {
        system = hpcSystem;
        overlays = [
          overlay
          hpcOverlay
        ];
        config.allowUnfree = true;
      };
      hpcUnstablePkgs = import inputs.nixpkgs-unstable {
        system = hpcSystem;
        config.allowUnfree = true;
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
            mkHome = userName: attrs: { home-manager.users.${userName} = attrs; };
          };
          modules = [
            hostPath
            nix-index-database.nixosModules.nix-index
            sops-nix.nixosModules.sops
            { nixpkgs.hostPlatform = system; }
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
            mkHome = userName: attrs: { home-manager.users.${userName} = attrs; };
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

      darwinConfigurations."macbook-pro-osx" = mkDarwin {
        system = "aarch64-darwin";
        hostPath = ./hosts/macbook-pro-m2/configuration.nix;
      };

      homeConfigurations = {
        hpc = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = hpcPkgs;
          modules = [ ./hosts/hpc/home.nix ];
          extraSpecialArgs = {
            inherit inputs;
            system = hpcSystem;
            mkHome = _: attrs: attrs;
            unstablePkgs = hpcUnstablePkgs;
          };
        };
      };
    };
}
