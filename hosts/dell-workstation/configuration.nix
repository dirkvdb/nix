{
  pkgs,
  unstablePkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix

    inputs.stylix.nixosModules.stylix

    # Dell Precision 7670: 12th gen Intel Core HX (Alder Lake) + Intel iGPU.
    (inputs.nixos-hardware + "/common/cpu/intel/alder-lake")
    # Precision 7670 dGPU options are NVIDIA RTX A-series mobile GPUs (Ampere).
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    (inputs.nixos-hardware + "/common/gpu/nvidia/ampere")
    # Generic laptop power/battery modules
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "25.11"; # Version at install time, never change

    stylix = {
      enable = true;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;

    # NVIDIA + Intel PRIME configuration for the Precision 7670 hybrid graphics
    # layout. common-gpu-nvidia enables PRIME offload and provides the
    # `nvidia-offload` wrapper; fine-grained power management lets the dGPU
    # fully power down when not in use.
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      dynamicBoost.enable = true;

      # Typical Precision 7670 Intel+iGPU / NVIDIA dGPU bus IDs. Verify with:
      #   lspci | grep -E 'VGA|3D|Display'
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    # Improve Gen12 Intel media scheduling and HuC/Guc firmware use.
    boot.kernelParams = [ "i915.enable_guc=3" ];

    # Dell Precision 7670 units are often configured with Intel VMD/RST for NVMe.
    # Including vmd keeps the initrd bootable even when the BIOS is left in RAID mode.
    boot.initrd.availableKernelModules = [ "vmd" ];

    # Dell Precision laptops benefit from firmware thermal controls, especially
    # under sustained workstation CPU/GPU loads.
    services.thermald.enable = true;

    # Precision 7670 has Thunderbolt 4 ports; bolt handles secure enrollment and
    # authorization of docks and external devices.
    services.hardware.bolt.enable = true;

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        # Adjust to the actual core count of your CPU
        cpu.cores = 16;
        binfmt.enable = true;

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
          };
        };

        loginmanager.tuigreet.enable = true;

        input.keyboard.via = true;

        audio.pipewire = {
          enable = true;
        };

        network = {
          enable = true;
          hostname = "p220248";

          networkmanager = {
            enable = true;
            wifi.backend = "wpa_supplicant";
          };
        };

        nfs-mounts = {
          enable = false;
          mounts = {
            "/nas/secrets" = {
              device = "nas.local:/volume2/secrets";
            };
            "/nas/ssd" = {
              device = "nas.local:/volume2/ssd";
            };
            "/nas/downloads" = {
              device = "nas.local:/volume1/downloads";
            };
            "/nas/data" = {
              device = "nas.local:/volume1/data";
            };
            "/nas/media" = {
              device = "nas.local:/volume1/media";
            };
          };
        };

        utils = {
          sysadmin = true;
          dev = true;
        };

        bluetooth = {
          enable = true;
        };
        video.nvidia.enable = true;

        fonts.enable = true;
      };

      services = {
        nordvpn = {
          enable = true;
          localDns = false;
        };
        ssh = {
          enable = true;
          disablePasswordAuth = true;
        };
        fwupd.enable = true;
        printing.enable = true;
        docker.enable = true;
        power-profiles-daemon.enable = true;
      };

      desktop = {
        enable = true;
        displayScale = 1.5;
        hyprland.enable = true;
      };

      apps = {
        direnv.enable = true;
        neovim.enable = true;
        slack.enable = true;
        sops.enable = true;
        spotify.enable = true;
        vscode.enable = true;
        whatsapp.enable = true;
        celluloid.enable = true;
        zathura.enable = true;
        zed = {
          enable = true;
          useLatestUpstream = false;
        };
      };

      home-manager = {
        ghostty.enable = true;
        teams.enable = true;

        keepassxc = {
          enable = true;
          databasePaths = [
            "${config.home-manager.users.dirk.xdg.dataHome}/secrets/Desktop.kdbx"
          ];
          keyfilePath = "${config.home-manager.users.dirk.xdg.dataHome}/secrets/desktop.key";

        };
      };
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools # intel_gpu_top and related tools
      appimage-run
      (remmina.override { withKf5Wallet = false; })
      qgis
      gnumeric
      teams-for-linux # add "secure": true to ~/.config/teams-for-linux/Preferences for camera to work
      unstablePkgs.winboat
    ];
  };
}
