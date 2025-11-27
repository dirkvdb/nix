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

    hardware.graphics.package =
      # Workaround for Mesa 25.3.0 regression causing firefox crashes
      # https://github.com/nix-community/nixos-apple-silicon/issues/380
      assert pkgs.mesa.version == "25.3.0";
      (import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/c5ae371f1a6a7fd27823bc500d9390b38c05fa55.tar.gz";
        sha256 = "sha256-4PqRErxfe+2toFJFgcRKZ0UI9NSIOJa+7RXVtBhy4KE=";
      }) { localSystem = pkgs.stdenv.hostPlatform; }).mesa;

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
    ];
  };
}
