{
  lib,
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

    # Dell Pro Max 16 (MC16250): Intel Core Ultra 7 265H (Arrow Lake-H) + Intel iGPU.
    # nixos-hardware has no dedicated arrow-lake module yet; Arrow Lake's graphics
    # tile is architecturally a Meteor Lake derivative (Xe-LPG+), so the meteor-lake
    # module is the closest match (sets the intel-media-driver VAAPI backend).
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    (inputs.nixos-hardware + "/common/cpu/intel/meteor-lake")
    (inputs.nixos-hardware + "/common/gpu/intel/meteor-lake")
    # Pro Max 16 dGPU options are NVIDIA RTX PRO mobile GPUs (Blackwell).
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    (inputs.nixos-hardware + "/common/gpu/nvidia/blackwell")
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

    # NVIDIA + Intel PRIME offload configuration for the Pro Max 16 hybrid
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

      # Bus IDs carried over from the Precision 7670; these are very likely to
      # differ on the Pro Max 16 and MUST be re-verified on the actual hardware:
      #   lspci | grep -E 'VGA|3D|Display'
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:2:0:0";
      };
    };

    # Broadcom 58200 / ControlVault fingerprint reader.
    # The reader requires Broadcom's unfree Touch OEM Driver rather than the
    # upstream libfprint driver.
    services.fprintd.tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-broadcom-cv3plus;
    };

    hardware.intelgpu = {
      driver = "i915";
    };

    boot.kernelParams = [
      # Expose a DRM framebuffer device on the NVIDIA GPU so that offload and
      # resume paths work correctly with the proprietary driver.
      "nvidia-drm.fbdev=1"
    ];

    # Modern Dell mobile workstations (Pro Max 16 included) only support s2idle
    # (Modern Standby), not S3 deep sleep. The NVIDIA driver defaults to
    # S3-style suspend handling; NVreg_EnableS0ixPowerManagement tells it to use
    # s0ix/s2idle paths instead.
    # Disable GSP firmware on the open driver: on Ampere mobile GPUs this caused
    # screen corruption, Wayland black windows, hangs, and poor resume behavior.
    # Re-verify whether this workaround is still needed on the Blackwell dGPU.
    boot.extraModprobeConfig = ''
      options nvidia NVreg_EnableS0ixPowerManagement=1 NVreg_EnableGpuFirmware=0
    '';

    # LUKS SSD performance tuning (allowDiscards + bypassWorkqueues) is applied
    # generically by modules/nixos/system/boot/disk-encryption to whichever
    # `luks-*` mapper devices back the file systems / swap, so no UUIDs are
    # hardcoded here (they change on every reinstall).

    # Dell mobile workstations are often configured with Intel VMD/RST for NVMe.
    # Including vmd keeps the initrd bootable even when the BIOS is left in RAID mode.
    boot.initrd.availableKernelModules = [ "vmd" ];

    # Dell mobile workstations benefit from firmware thermal controls, especially
    # under sustained workstation CPU/GPU loads.
    services.thermald.enable = true;

    # Pro Max 16 has Thunderbolt 4 ports; bolt handles secure enrollment and
    # authorization of docks and external devices.
    services.hardware.bolt.enable = true;

    # PCI addresses verified against the Pro Max 16's actual hardware via `lspci`:
    # Intel iGPU at 0000:00:02.0, NVIDIA RTX PRO 1000 Blackwell dGPU at 0000:02:00.0.
    # The touchpad ACPI path below was carried over from the old Precision 7670
    # and still needs re-verification (`cat /proc/bus/input/devices` or `i2cdetect`).
    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:02:00.0", SYMLINK+="dri/nvidia-dgpu"
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/intel-igpu"

      # The I2C HID touchpad (VEN_0488 / Synaptics at _SB_.PC00.I2C1.TPD0)
      # generates GPIO interrupts (IRQ 14 / INTC1056) that immediately wake
      # the system from s2idle. Disable wakeup on this device.
      # ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-VEN_0488:00", ATTR{power/wakeup}="disabled"

      # Broadcom 58200 / ControlVault fingerprint reader: the actual hardware
      # enumerates as USB 0a5c:5863, which is not in the cv3plus driver
      # package's published udev/modalias list (only 5864-5867 are declared
      # there; the plain "v3" package only covers 5842-5845). 5863 is most
      # likely an unlisted PID of the same v3+ chip generation on this very
      # new Dell Pro Max 16 (MC16250), so route it to the cv3plus TOD driver
      # as well. libfprint only needs ENV{LIBFPRINT_DRIVER} set to attempt
      # loading the driver for a device; remove this rule if it turns out
      # cv3plus genuinely doesn't support this revision.
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="5863", ATTRS{dev}=="*", TEST=="power/control", ATTR{power/control}="auto"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="5863", ENV{LIBFPRINT_DRIVER}="Broadcom Sensors"
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
        # Intel Core Ultra 7 265H: 6 P-cores + 8 E-cores + 2 LP E-cores = 16 cores.
        # Arrow Lake has no SMT, so this is also the logical processor count.
        cpu.cores = 16;
        performance.enable = true;
        binfmt.enable = true;

        nix = {
          ld.enable = true;
          nh.configurationName = "dell-workstation";
        };

        kernel.useLatest = true;

        boot = {
          secureboot.enable = true;
          graphical = true;
          initrd-bluetooth = {
            enable = true;
            extraFirmwarePaths = [
              "intel/ibt-0291-0291.sfi"
              "intel/ibt-0291-0291.ddc"
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
          hostname = "p260182";

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
        display.brightnesscontrol = {
          enable = true;
          i2cDevice = "i2c-11";
          # Dell U2725QE fails the ddcci driver's identification probe with
          # the default 60ms delay (dmesg: "core device probe failed: -19"),
          # even though ddcutil communicates with it over DDC/CI just fine.
          delay = 200;
        };

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
        hyprland.devWorkspaceGapSize = 1; # avoid flickering on the dell monitors with lower dpi due to fractional scaling
        noctalia = {
          enable = true;
          fingerprint.enable = true;
        };
      };

      apps = {
        aichat.enable = true;
        bitwarden.enable = true;
        celluloid.enable = true;
        chatgpt.enable = true;
        direnv.enable = true;
        ghostty.enable = true;
        herdr.enable = true;
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
        voxtype.enable = true;
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
      onlyoffice-desktopeditors
      unstablePkgs.ferdium
      qtcreator
    ];
  };
}
