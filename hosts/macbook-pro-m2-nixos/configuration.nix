{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix

    inputs.stylix.nixosModules.stylix
    inputs.apple-silicon.nixosModules.apple-silicon-support
    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    {
      _module.args.unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
    }
  ];

  config = {
    system.stateVersion = "25.05"; # Version at install time, never change

    stylix = {
      enable = true;
    };

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        cpu.cores = 12;

        nix = {
          unfree.enable = true;
          nh.enable = true;
          ld.enable = true;
          flakes.enable = true;
        };

        boot = {
          systemd = {
            enable = true;
            graphical = true;
            canTouchEfi = false;
          };
        };

        loginmanager.tuigreet.enable = true;

        input.keyboard.via = true;

        audio.pipewire = {
          enable = true;
          airplay = false;
        };

        network = {
          enable = true;
          hostname = "macbook-pro";

          wifi = {
            enable = true;
          };
        };

        nfs-mounts = {
          enable = true;
          mounts = {
            "/nas/secrets" = {
              device = "nas.local:/volume2/secrets";
            };
            "/nas/ssd" = {
              device = "nas.local:/volume2/ssd";
            };
          };
        };

        utils = {
          dev = true;
          sysadmin = true;
        };

        bluetooth.enable = true;
        fonts.enable = true;
      };

      services = {
        ssh.enable = true;
        fwupd.enable = true;
        printing.enable = true;
        power-profiles-daemon.enable = true;
      };

      desktop = {
        enable = true;
        displayScale = 2.0;
        hyprland.enable = true;
      };

      apps = {
        bitwarden.enable = false;
        prusa-slicer.enable = false;
        brave.enable = true;
        spotify.enable = false;
        localsend.enable = true;
        vscode.enable = true;
      };

      home-manager = {
        ghostty.enable = true;

        keepassxc = {
          enable = true;
          databasePaths = [
            "/nas/ssd/secrets/Desktop.kdbx"
          ];
          keyfilePath = "/nas/secrets/desktop.key";
        };
      };
    };

    # Disable peripheral firmware extraction
    hardware.asahi.enable = true;
    # hardware.asahi.extractPeripheralFirmware = true;
    hardware.asahi.peripheralFirmwareDirectory = ./firmware;

    # Swap fn and left ctrl keys on MacBook keyboard
    # fnmode=2 Use function keys by default
    boot.extraModprobeConfig = ''
      options hid-apple swap_fn_leftctrl=1
      options hid-apple swap_opt_cmd=1
      options hid_apple fnmode=2
    '';

    services.libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        middleEmulation = false;
        tapping = true;
        naturalScrolling = true;
      };
    };

    environment.systemPackages = with pkgs; [
      teams-for-linux
      vulkan-tools
      brightnessctl
      (psst.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "jpochyla";
          repo = "psst";
          rev = "3846f9c736ee771342622df86aafb34286dab2aa";
          hash = "sha256-HtDRtQVrEzpyE06eU5ekGxyFpQ3qnU9DCfpvHpI/ESA=";
        };
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/jpochyla/psst/3846f9c736ee771342622df86aafb34286dab2aa/Cargo.lock";
            hash = "sha256-Ey4Y/kHOYdgIoFFPZg9sZAivKZdGvkhtXZJhIeFLFRc=";
          };
          outputHashes = {
            "cubeb-0.27.0" = "sha256-qq+AM9GbD0DAVcr2VrbtxDpSkb/FOMY75IQylXVG5Uw=";
            "cubeb-core-0.27.0" = "sha256-qq+AM9GbD0DAVcr2VrbtxDpSkb/FOMY75IQylXVG5Uw=";
            "cubeb-sys-0.27.0" = "sha256-qq+AM9GbD0DAVcr2VrbtxDpSkb/FOMY75IQylXVG5Uw=";
            "druid-0.8.3" = "sha256-O9CBDRHcyDxa0MAqTtOipn0EPnm7o//bdQX/3hZpSJM=";
            "druid-derive-0.5.1" = "sha256-O9CBDRHcyDxa0MAqTtOipn0EPnm7o//bdQX/3hZpSJM=";
            "druid-enums-0.1.0" = "sha256-KJvAgKxicx/g+4QRZq3iHt6MGVQbfOpyN+EhS6CyDZk=";
            "druid-shell-0.8.3" = "sha256-O9CBDRHcyDxa0MAqTtOipn0EPnm7o//bdQX/3hZpSJM=";
          };
        };
        patches = [ ];
        postPatch = ''
                    # Patch the git_version macro to always return "dev"
                    substituteInPlace psst-core/src/lib.rs \
                      --replace 'pub const GIT_VERSION: &str = git_version!();' 'pub const GIT_VERSION: &str = "dev";'

                    # Create a fake .git directory structure for the build script
                    mkdir -p .git
                    cat > .git/config << 'EOF'
          [remote "origin"]
          	url = https://github.com/jpochyla/psst
          EOF
        '';
      }))
    ];
  };
}
