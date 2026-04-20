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
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    {
      _module.args.unstablePkgs = import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    }
  ];

  config = {
    system.stateVersion = "25.11";

    stylix.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
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
        cpu.cores = 4;

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

        audio.pipewire = {
          enable = true;
          airplay = false;
        };

        network = {
          enable = true;
          hostname = "mediastation";

          ethernet = {
            enable = true;
            wakeOnLan = true;
            interface = "en2ps0";
            dhcp = "ipv4";
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
        docker.enable = true;
        power-profiles-daemon.enable = true;
      };

      desktop = {
        enable = true;
        hyprland.enable = true;
      };

      apps = {
        neovim.enable = true;
        sops.enable = true;
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
  };
}
