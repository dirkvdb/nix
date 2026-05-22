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

    # Intel Tiger Lake CPU + Intel Xe/Iris Xe GPU
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    # Minimal NVIDIA module: just sets videoDrivers=["nvidia"].
    # Switch to common-gpu-nvidia (PRIME offload) once Bus IDs are confirmed.
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
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

    # NVIDIA + Intel PRIME configuration.
    # common-gpu-nvidia already handles: videoDrivers=["nvidia"], prime.offload.enable,
    # and the nvidia-offload wrapper command.
    # Verify Bus IDs on your hardware with: lspci | grep -E 'VGA|3D'
    # then convert to PCI:bus:device:function notation.
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      # powerManagement.finegrained requires PRIME offload — re-enable with prime block
      # powerManagement.finegrained = true;
      open = false; # use proprietary driver (best support for Turing-era hardware)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # TODO: fill in after first boot (`lspci | grep -E 'VGA|3D'`), then
      # switch the import above to common-gpu-nvidia (PRIME offload).
      # prime = {
      #   intelBusId = "PCI:0:2:0";
      #   nvidiaBusId = "PCI:1:0:0";
      # };
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
