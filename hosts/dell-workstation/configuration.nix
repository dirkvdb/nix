{
  lib,
  pkgs,
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
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    (inputs.nixos-hardware + "/common/cpu/intel/alder-lake")
    (inputs.nixos-hardware + "/common/gpu/intel/alder-lake")
    # Precision 7670 dGPU options are NVIDIA RTX A-series mobile GPUs (Ampere).
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    (inputs.nixos-hardware + "/common/gpu/nvidia/ampere")
    # Generic laptop power/battery modules
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "26.05"; # Version at install time, never change

    stylix = {
      enable = true;
    };

    nix.settings = {
      substituters = [
        "https://cache.nixos-cuda.org"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };

    # NVIDIA + Intel PRIME offload configuration for the Precision 7670 hybrid
    # graphics layout. The Intel iGPU drives all displays; the NVIDIA dGPU is
    # available via offload (nvidia-offload <cmd>) and powers down when idle.
    hardware.nvidia = {
      branch = "latest";
      powerManagement = {
        # Registers nvidia-suspend / nvidia-resume systemd services so the GPU
        # saves state and enters D3 during s2idle. Without this the platform
        # never reaches S0ix (slp_s0_residency stays 0) and the EC immediately
        # wakes the system.
        enable = true;
        # Fine-grained PM (D3cold): the dGPU powers off completely when no
        # offload workload is running, saving significant battery.
        finegrained = true;
      };
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Typical Precision 7670 Intel+iGPU / NVIDIA dGPU bus IDs. Verify with:
      #   lspci | grep -E 'VGA|3D|Display'
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    hardware.intelgpu = {
      driver = "i915";
    };

    boot.kernelParams = [
      # Expose a DRM framebuffer device on the NVIDIA GPU so that offload and
      # resume paths work correctly with the proprietary driver.
      "nvidia-drm.fbdev=1"
    ];

    # Alder Lake Dell Precision 7670 only supports s2idle (Modern Standby), not
    # S3 deep sleep. The NVIDIA driver defaults to S3-style suspend handling;
    # NVreg_EnableS0ixPowerManagement tells it to use s0ix/s2idle paths instead.
    # Disable GSP firmware on the open driver: on Ampere mobile GPUs it causes
    # screen corruption, Wayland black windows, hangs, and poor resume behavior.
    boot.extraModprobeConfig = ''
      options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_EnableGpuFirmware=0
    '';

    # LUKS performance options for NVMe SSD
    boot.initrd.luks.devices."luks-8dce0af5-f867-40c7-b060-02f5af164340" = {
      # Pass TRIM/discard through the encryption layer so the SSD can reclaim
      # deleted blocks, preserving write performance over time.
      allowDiscards = true;
      # Skip dm-crypt's internal workqueues and submit crypto ops directly;
      # avoids unnecessary context switches on NVMe which already has efficient
      # multi-queue I/O scheduling.
      bypassWorkqueues = true;
    };
    boot.initrd.luks.devices."luks-faf7f7e5-6171-4339-9e32-bd7a858c8ae2" = {
      allowDiscards = true;
      bypassWorkqueues = true;
    };

    # Dell Precision 7670 units are often configured with Intel VMD/RST for NVMe.
    # Including vmd keeps the initrd bootable even when the BIOS is left in RAID mode.
    boot.initrd.availableKernelModules = [ "vmd" ];

    # Dell Precision laptops benefit from firmware thermal controls, especially
    # under sustained workstation CPU/GPU loads.
    services.thermald.enable = true;

    # Precision 7670 has Thunderbolt 4 ports; bolt handles secure enrollment and
    # authorization of docks and external devices.
    services.hardware.bolt.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-dgpu"
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/intel-igpu"

      # The I2C HID touchpad (VEN_0488 / Synaptics at _SB_.PC00.I2C1.TPD0)
      # generates GPIO interrupts (IRQ 14 / INTC1056) that immediately wake
      # the system from s2idle. Disable wakeup on this device.
      ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-VEN_0488:00", ATTR{power/wakeup}="disabled"
    '';

    home-manager.users.dirk.programs.fish.shellInit = lib.mkAfter ''
      set -gx ARTIFACTORY_TOKEN (cat ${config.sops.secrets.artifactory_token.path} | string trim)
    '';

    # Intel iGPU drives the compositor. The NVIDIA dGPU is available for
    # offload only; list it second so Hyprland prefers the iGPU.
    # AQ_DRM_DEVICES is colon-separated, so use colon-free udev symlinks instead
    # of /dev/dri/by-path names such as pci-0000:01:00.0-card.
    home-manager.users.dirk.wayland.windowManager.hyprland.settings.env = lib.mkAfter [
      {
        _args = [
          "AQ_DRM_DEVICES"
          "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu"
        ];
      }
    ];

    # Specialisation: NVIDIA dGPU drives all compositing (current/legacy setup).
    # Switch at runtime with:
    #   sudo /run/current-system/specialisation/nvidia-primary/bin/switch-to-configuration test
    # Or select "nvidia-primary" from the bootloader menu.
    specialisation.nvidia-primary.configuration = {
      system.nixos.tags = [ "nvidia-primary" ];

      hardware.nvidia.powerManagement.finegrained = lib.mkForce false;

      home-manager.users.dirk.wayland.windowManager.hyprland.settings.env = lib.mkForce [
        {
          _args = [
            "AQ_DRM_DEVICES"
            "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu"
          ];
        }
        {
          _args = [
            "GBM_BACKEND"
            "nvidia-drm"
          ];
        }
        # {
        #   _args = [
        #     "__GLX_VENDOR_LIBRARY_NAME"
        #     "nvidia"
        #   ];
        # }
      ];
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
        # Adjust to the actual core count of your CPU
        cpu.cores = 24;
        binfmt.enable = true;

        nix = {
          ld.enable = true;
          nh.configurationName = "dell-workstation";
        };

        boot = {
          secureboot.enable = true;
          graphical = true;
          initrd-bluetooth = {
            enable = true;
            extraFirmwarePaths = [
              "intel/ibt-1040-0041.sfi"
              "intel/ibt-1040-0041.ddc"
            ];
          };
        };

        loginmanager.sddm = {
          enable = true;
          autologin = {
            enable = true;
            user = "dirk";
          };
        };

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
            vpn.homeVpn = true;
          };
        };

        nfs-mounts = {
          enable = true;
          presets.nas = true;
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
        ssh = {
          enable = true;
          disablePasswordAuth = true;
        };
        fwupd.enable = true;
        hyprmoncfg.enable = true;
        printing.enable = true;
        docker.enable = true;
        power-profiles-daemon.enable = true;
        syncthing = {
          enable = true;
          shares.secrets = true;
        };
        vpnjumphost = {
          enable = true;
          pac.enable = true;
        };
        officework.enable = true;
      };

      desktop = {
        enable = true;
        displayScale = 1.5;
        waybar.enable = true;
      };

      apps = {
        aichat.enable = true;
        celluloid.enable = true;
        direnv.enable = true;
        ghostty.enable = true;
        keepassxc = {
          enable = true;
          databasePaths = [
            "${config.local.services.syncthing.shares.secretsPath}/Desktop.kdbx"
          ];
          keyfilePath = "${config.local.user.homeDir}/.local/share/desktop.key";
        };
        neovim.enable = true;
        qgis.enable = true;
        remmina = {
          enable = true;
          connections = {
            EISSDESK = {
              name = "EISSDESK";
              server = "eissdesk.vito.local";
              drive = "/work/transfer";
              protocol = "RDP";
              ignore-tls-errors = 1;
              proxy_type = "socks5";
              proxy_hostname = "127.0.0.1";
              proxy_port = 1080;
            };
            VITO = {
              name = "VITO";
              server = "vitord2016.vito.local";
              drive = "/work/transfer";
              protocol = "RDP";
              proxy_type = "socks5";
              proxy_hostname = "127.0.0.1";
              proxy_port = 1080;
            };
          };
        };
        slack.enable = true;
        sops.enable = true;
        spotify.enable = true;
        teams.enable = true;
        vscode.enable = true;
        whatsapp.enable = true;
        winboat.enable = true;
        zathura.enable = true;
        zed = {
          enable = true;
          useLatestUpstream = false;
        };
        zellij.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools # intel_gpu_top and related tools
      appimage-run
      gnumeric
      onlyoffice-desktopeditors
      gitcomet
    ];
  };
}
