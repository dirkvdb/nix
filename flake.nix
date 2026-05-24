{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinned nixpkgs with freeimage (removed from newer nixpkgs due to vulnerabilities).
    # Needed to build ES-DE from source.
    nixpkgs-freeimage.url = "github:nixos/nixpkgs/nixos-24.11";
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

    librepods = {
      url = "github:kavishdevar/librepods/linux/rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nmrs-gui = {
      url = "github:networkmanager-rs/nmrs-gui";
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
      # Import unstable for ROCm packages
      unstablePkgs =
        system:
        import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      # Custom packages overlay
      overlay = final: prev: {
        plymouth-theme-nixos = prev.callPackage ./pkgs/plymouth-theme-nixos { };
        cpp-httplib = prev.callPackage ./pkgs/cpp-httplib {
          zlib = prev."zlib-ng".override {
            withZlibCompat = true;
          };
        };

        freeimage-pinned =
          let
            legacyPkgs = import inputs.nixpkgs-freeimage {
              system = prev.stdenv.hostPlatform.system;
              config.permittedInsecurePackages = [ "freeimage-unstable-2021-11-01" ];
            };
          in
          legacyPkgs.freeimage;
        es-de = prev.callPackage ./pkgs/es-de { freeimage = final.freeimage-pinned; };
        nmrs-gui = prev.callPackage "${inputs.nmrs-gui}/package.nix" {
          # set rustplatform to the nixpkgs version instead of upstreams naersk platform
          rustPlatform =
            (import inputs.nixpkgs-unstable { system = prev.stdenv.hostPlatform.system; }).rustPlatform;
        };
        lemonade-server = prev.callPackage ./pkgs/lemonade/server.nix {
          lemonade-web-app-bundle = final.lemonade-web-app-bundle;
        };
        lemonade-app = prev.callPackage ./pkgs/lemonade/app.nix { };
        lemonade-web-app-bundle = prev.callPackage ./pkgs/lemonade/web-app-bundle.nix { };
        decentpaste = prev.callPackage ./pkgs/decentpaste { };
        sunshine = prev.callPackage ./pkgs/sunshine { };
        nordvpn = prev.callPackage ./pkgs/nordvpn { };
        hyprmoncfg = prev.callPackage ./pkgs/hyprmoncfg { };
        librepods = inputs.librepods.packages.${prev.stdenv.hostPlatform.system}.default;

        # Pin Sublime Merge to Build 2125
        sublime-merge = prev.callPackage (import
          "${inputs.nixpkgs}/pkgs/applications/version-management/sublime-merge/common.nix"
          {
            buildVersion = "2125";
            aarch64sha256 = "18nwydssnmbzkxg7bp49bf33hnmmjl0zv5sq8l50x4san4libkk6";
            x64sha256 = "1xs7ap0njcly5y6kppfs6i3xv62wsd0jwjkfa11n2vscfvi6z6fi";
          }
        ) { };

        # Patch keepassxc to include NativeMessageInstaller.patch
        # This avoids error messages at startup that the browser connection files cannot be written
        # They are readonly because they are managed by the Nix config
        keepassxc = prev.keepassxc.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./modules/home/apps/keepassxc/NativeMessageInstaller.patch
          ];
        });

        # Upgrade wluma to 4.11.0 which adds Apple Silicon ALS sensor support
        # https://github.com/maximbaz/wluma/releases/tag/4.11.0
        # Apply patch to ignore 0 brightness level
        wluma = prev.wluma.overrideAttrs (old: rec {
          patches = (old.patches or [ ]) ++ [
            (prev.fetchpatch {
              url = "https://github.com/max-baz/wluma/commit/d147833706eff058840fb2c53206e223380fbf3b.patch";
              hash = "sha256-iRYYzpe7aq1/urhZjPqKQEnSTJTH5A1OjeYq+fALNeo=";
            })
          ];
          version = "4.11.0";
          src = prev.fetchFromGitHub {
            owner = "maximbaz";
            repo = "wluma";
            rev = version;
            hash = "sha256-kisxv+CYouYpVTULmjvDEGucha+/T+gQJEsGyTQkQLk=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-qL+OnnPlQoGj7gvpYegjwN42skKUsbg+FV3cnTBwNpo=";
          };
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
            unstablePkgs = unstablePkgs system;
            mkHome = userName: attrs: { home-manager.users.${userName} = attrs; };
          };
          modules = [
            hostPath
            nix-index-database.nixosModules.nix-index
            sops-nix.nixosModules.sops
            inputs.nixflix.nixosModules.default
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

        mediastation = mkNixos {
          system = "x86_64-linux";
          hostPath = ./hosts/mediastation/configuration.nix;
        };
        macmini = mkNixos {
          system = "x86_64-linux";
          hostPath = ./hosts/macmini/configuration.nix;
        };

        dell-workstation = mkNixos {
          system = "x86_64-linux";
          hostPath = ./hosts/dell-workstation/configuration.nix;
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
