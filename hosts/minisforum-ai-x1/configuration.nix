{
  pkgs,
  userConfig,
  inputs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/common/import.nix
    ../../modules/home/import.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "25.05"; # Version at install time, never change

    # Use the latest kernel from unstable (for better AMD CPU support)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      system = {
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

        input.keyboard.via = true;

        audio.pipewire = {
          enable = true;
          airplay = true;
        };

        video.amd.enable = true;
        display.brightnesscontrol = {
          enable = true;
          i2cDevice = "i2c-13";
        };

        network = {
          enable = true;
          hostname = userConfig.hostname;

          ethernet = {
            enable = true;
            wakeOnLan = true;
            interface = "enp195s0";
            dhcp = "ipv4";
          };
        };

        nfs-mounts = {
          enable = true;
          mounts = {
            "/nas/secrets" = {
              device = "192.168.1.13:/volume2/secrets";
            };
            "/nas/ssd" = {
              device = "192.168.1.13:/volume2/ssd";
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
      };

      desktop = {
        enable = true;
        hyprland.enable = true;
      };

      apps = {
        ghostty.enable = true;
        bitwarden.enable = true;
        prusa-slicer.enable = true;
        vivaldi.enable = true;
        spotify.enable = true;
      };

      home-manager = {
        keepassxc = {
          enable = true;
          databasePath = "/nas/ssd/google_drive_dirk/Secrets/Desktop.kdbx";
          keyfilePath = "/nas/secrets/desktop.key";
        };
      };
    };

    services = {
      printing.enable = true;

      greetd = {
        enable = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --remember --time --cmd 'hyprland'";
      };
    };

    programs = {
      direnv.enable = true;
      localsend.enable = true;
    };

    environment.systemPackages = with pkgs; [
      mako # notifications
      swayosd

      # works
      slack
      teams-for-linux
    ];
  };
}
