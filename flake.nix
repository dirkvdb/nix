{
  description = "nix system flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-chatgpt.url = "github:amielke/nixpkgs/chatgpt-linux";
    # Pinned nixpkgs with freeimage (removed from newer nixpkgs due to vulnerabilities).
    # Needed to build ES-DE from source.
    nixpkgs-freeimage.url = "github:nixos/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    ai-usagebar = {
      url = "github:akitaonrails/ai-usagebar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
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

    librepods = {
      url = "github:kavishdevar/librepods/linux/rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    vpn-jumphost = {
      url = "github:VITO-RMA/vpn-jumphost";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-amd-ai = {
      url = "github:noamsto/nix-amd-ai";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do not override nixpkgs; must match the kernel patches
    };

    hyprexpose = {
      url = "github:ThiagoAVicente/hyprexpose";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silent-sddm = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.0.0-beta.10";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tether = {
      url = "github:zackb/tether";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fastpotify = {
      url = "github:crmne/fastpotify";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-index-database,
      nixos-wsl,
      sops-nix,
      darwin,
      lanzaboote,
      ...
    }@inputs:
    let
      # Import unstable for ROCm packages
      unstablePkgs =
        system:
        import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          # winboat bundles electron_40, which nixpkgs currently marks
          # insecure (EOL). Allow it explicitly.
          config.permittedInsecurePackages = [ "electron-40.10.5" ];
        };

      chatgptPkgs =
        system:
        let
          pkgs = import inputs.nixpkgs-chatgpt {
            inherit system;
            config.allowUnfree = true;
          };
        in
        if system == "aarch64-linux" then
          pkgs
          // {
            # OpenAI replaces the artifact behind its `latest` URL without changing the PR.
            chatgpt = pkgs.chatgpt.overrideAttrs (old: {
              src = pkgs.fetchurl {
                url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_arm64.deb";
                hash = "sha256-El42Ui1Dx1vXlYR3hGumsc3fLrGc78tX3agL4XQvkX8=";
              };
              autoPatchelfIgnoreMissingDeps = old.autoPatchelfIgnoreMissingDeps ++ [
                "libc++_shared.so"
                "liblog.so"
              ];
              # autoPatchelf moves PT_INTERP beyond detect-libc's 2 KiB scan.
              # Its process.report fallback trips Electron's CFI, so use the
              # glibc watcher. The fork's custom unpack phase puts the files
              # below source/ rather than at the derivation root.
              postUnpack = ''
                grep -aFq 'const family = familySync();' source/usr/lib/chatgpt/resources/app.asar
                sed -i "s|const family = familySync();|const family = 'glibc'     ;|" source/usr/lib/chatgpt/resources/app.asar
              '';
            });
          }
        else
          pkgs
          // {
            # OpenAI replaces the artifact behind its `latest` URL without changing the PR.
            chatgpt = pkgs.chatgpt.overrideAttrs (_old: {
              src = pkgs.fetchurl {
                url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
                hash = "sha256-NVSwAixs+1EzJvQ/0R9xiDWncIasTXyi/z67ui1Mf0U=";
              };
              # autoPatchelf moves PT_INTERP beyond detect-libc's 2 KiB scan.
              # Its process.report fallback trips Electron's CFI, so use the
              # glibc watcher. The fork's custom unpack phase puts the files
              # below source/ rather than at the derivation root.
              postUnpack = ''
                grep -aFq 'const family = familySync();' source/usr/lib/chatgpt/resources/app.asar
                sed -i "s|const family = familySync();|const family = 'glibc'     ;|" source/usr/lib/chatgpt/resources/app.asar
              '';
            });
          };

      # Custom packages overlay
      overlay = final: prev: {
        # Override aquamarine to 0.12.1 to fix split-node GPU render node fallback on Apple Silicon
        # https://github.com/hyprwm/aquamarine/pull/291
        # Remove this override once nixpkgs ships aquamarine >= 0.12
        aquamarine =
          if prev.stdenv.hostPlatform.isAarch64 && prev.stdenv.hostPlatform.isLinux then
            assert prev.lib.versionOlder prev.aquamarine.version "0.12";
            prev.aquamarine.overrideAttrs (old: {
              version = "0.12.1";
              src = prev.fetchFromGitHub {
                owner = "hyprwm";
                repo = "aquamarine";
                tag = "v0.12.1";
                hash = "sha256-cUQENbJn0PHQUttXame5+PbGGew+BckHZFTfpb8XGI8=";
              };
            })
          else
            prev.aquamarine;

        plymouth-theme-nixos = prev.callPackage ./pkgs/plymouth-theme-nixos { };
        freeimage-pinned =
          let
            legacyPkgs = import inputs.nixpkgs-freeimage {
              system = prev.stdenv.hostPlatform.system;
              config.permittedInsecurePackages = [ "freeimage-unstable-2021-11-01" ];
            };
          in
          legacyPkgs.freeimage;
        es-de = prev.callPackage ./pkgs/es-de { freeimage = final.freeimage-pinned; };
        decentpaste = prev.callPackage ./pkgs/decentpaste { };
        make-slack-great-again = prev.callPackage ./pkgs/make-slack-great-again { };
        hyprmoncfg = prev.callPackage ./pkgs/hyprmoncfg { };
        siffra = prev.callPackage ./pkgs/siffra { };
        tether = inputs.tether.packages.${prev.stdenv.hostPlatform.system}.tether;
        fastpotify = inputs.fastpotify.packages.${prev.stdenv.hostPlatform.system}.fastpotify;
        librepods = inputs.librepods.packages.${prev.stdenv.hostPlatform.system}.default;
        hyprexpose = inputs.hyprexpose.packages.${prev.stdenv.hostPlatform.system}.default;

        # Patch waybar to support Hyprland 0.55+ Lua IPC protocol
        # https://github.com/Alexays/Waybar/pull/5013
        waybar = prev.waybar.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./modules/home/apps/hyprland/waybar-lua-ipc.patch
          ];
        });

        # Pin Sublime Merge to Build 2125
        sublime-merge = prev.callPackage (import
          "${inputs.nixpkgs}/pkgs/applications/version-management/sublime-merge/common.nix"
          {
            buildVersion = "2125";
            aarch64sha256 = "18nwydssnmbzkxg7bp49bf33hnmmjl0zv5sq8l50x4san4libkk6";
            x64sha256 = "1xs7ap0njcly5y6kppfs6i3xv62wsd0jwjkfa11n2vscfvi6z6fi";
          }
        ) { };

        # Also apply TrayNotificationMonochromeIcon.patch: when a secret is accessed via the
        # Secret Service API/browser integration, KeePassXC shows a desktop notification using
        # QSystemTrayIcon::showMessage() with the full-color application icon. On Linux this is
        # implemented via the StatusNotifierItem AttentionIconPixmap, causing tray hosts (e.g.
        # Noctalia) to briefly replace the configured monochrome tray icon with the colored one.
        # The patch reuses the monochrome-aware tray icon for this notification instead.
        # keepassxc = prev.keepassxc.overrideAttrs (old: {
        #   patches = (old.patches or [ ]) ++ [
        #     ./modules/home/apps/keepassxc/TrayNotificationMonochromeIcon.patch
        #   ];
        # });
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
            inherit inputs system self;
            unstablePkgs = unstablePkgs system;
            chatgptPkgs = chatgptPkgs system;
            mkHome = userName: attrs: { home-manager.users.${userName} = attrs; };
          };
          modules = [
            hostPath
            lanzaboote.nixosModules.lanzaboote
            nix-index-database.nixosModules.nix-index
            sops-nix.nixosModules.sops
            inputs.nixflix.nixosModules.default
            inputs.nix-amd-ai.nixosModules.default
            inputs.silent-sddm.nixosModules.default
            inputs.noctalia.nixosModules.default
            { nixpkgs.hostPlatform = system; }
            {
              nixpkgs.overlays = [
                overlay
                inputs.vpn-jumphost.overlays.default
              ]
              ++ extraOverlays;
            }
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
            unstablePkgs = unstablePkgs system;
            chatgptPkgs = chatgptPkgs system;
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
      overlays.default = overlay;

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

        # Installer ISO
        installer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self; };
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            ./hosts/installer/configuration.nix
            { nixpkgs.hostPlatform = "x86_64-linux"; }
          ];
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
