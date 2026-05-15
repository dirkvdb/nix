{
  pkgs,
  unstablePkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix

    inputs.stylix.nixosModules.stylix
    inputs.nixos-hardware.nixosModules.apple-t2
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "25.11";

    stylix.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
      ];
    };

    hardware.apple-t2.firmware.enable = true;

    hardware.intelgpu = {
      computeRuntime = "legacy";
      vaapiDriver = "intel-media-driver";
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
        cpu.cores = 6;

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

        bluetooth.enable = true;

        loginmanager.tuigreet.enable = true;

        audio.pipewire = {
          enable = true;
          airplay = false;
        };
        network = {
          enable = true;
          hostname = "macmini";
          networkmanager = {
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
            "/nas/downloads" = {
              device = "nas.local:/volume1/downloads";
            };
            "/nas/data" = {
              device = "nas.local:/volume1/data";
            };
            "/nas/media" = {
              device = "nas.local:/volume1/media";
            };
            "/nas/arr" = {
              device = "nas.local:/volume1/arr";
            };
          };
        };

        utils = {
          dev = false;
          sysadmin = true;
        };

        fonts.enable = true;
      };

      services = {
        ssh = {
          enable = true;
          disablePasswordAuth = true;
        };
        fwupd.enable = true;
        power-profiles-daemon.enable = true;
        nixflix.enable = true;
        sunshine.enable = true;
      };

      desktop = {
        enable = true;
        hyprland.enable = true;
      };

      apps = {
        moonlight.enable = true;
        neovim.enable = true;
        sops.enable = true;
        steam.enable = true;
        zed.enable = true;
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

    environment.systemPackages = with pkgs; [
      just
      unstablePkgs.fladder
    ];
  };
}
