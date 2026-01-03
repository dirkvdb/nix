{
  pkgs,
  inputs,
  config,
  ...
}:
let
  inherit (config.local) user;
in
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
      _module.args.unstablePkgs =
        inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
        mqtt.enable = true;
        localsend.enable = true;
        neovim.enable = true;
        vscode.enable = true;
        vlc.enable = true;
        sops = {
          enable = true;
          ageKeyFile = {
            path = "${user.homeDir}/.config/sops/age/keys.txt";
          };
        };
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
      options apple_dcp show_notch=1
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
