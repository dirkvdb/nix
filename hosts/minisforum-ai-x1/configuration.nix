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
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "25.05"; # Version at install time, never change

    stylix = {
      enable = true;
    };

    # Use the latest kernel from unstable (for better AMD CPU support)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        cpu.cores = 20;
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
          airplay = false;
        };

        video.amd.enable = true;
        display.brightnesscontrol = {
          enable = true;
          i2cDevice = "i2c-13";
        };

        network = {
          enable = true;
          hostname = "mini";
          wakeOnLan = true;
          interface = "enp195s0";

          networkmanager = {
            enable = true;
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
          sixaxis = true;
        };
        fonts.enable = true;
      };

      services = {
        nordvpn = {
          enable = true;
          localDns = true;
        };
        ssh = {
          enable = true;
          disablePasswordAuth = true;
        };
        fwupd.enable = true;
        printing.enable = true;
        sunshine.enable = true;
        docker.enable = true;
        power-profiles-daemon.enable = true;
      };

      desktop = {
        enable = true;
        displayScale = 1.666667;
        hyprland.enable = true;
        monitors = [
          # Place the Dell secondary monitor to the left of the main LG 4K monitor
          # "HDMI-A-1,preferred,auto-left,1.0,transform,1"
          "HDMI-A-1,preferred,auto-left,1.0"
        ];
        primaryMonitor = "DP-3";
        workspaces = [
          # Bind secondary workspaces to HDMI-A-1 so it is never the main monitor
          "9, monitor:HDMI-A-1, default:true, persistent:true"
          "10, monitor:HDMI-A-1, persistent:true"
        ];
      };

      apps = {
        direnv.enable = true;
        lan-mouse.enable = true;
        lemonade = {
          enable = true;
          llamacppBackend = "rocm";
          contextSize = 16000;
          extraModelsDir = /models;
        };
        librepods.enable = true;
        localsend.enable = true;
        moonlight.enable = true;
        mqtt.enable = true;
        neovim.enable = true;
        prusa-slicer.enable = true;
        retro-emulation.enable = true;
        slack.enable = true;
        fladder.enable = true;
        sops.enable = true;
        spotify.enable = true;
        vscode.enable = true;
        whatsapp.enable = true;
        celluloid.enable = true;
        zathura.enable = true;
        zed = {
          enable = true;
          useLatestUpstream = true;
        };
      };

      home-manager = {
        ghostty.enable = true;
        teams.enable = true;

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
      appimage-run
      qgis
      gnumeric
      teams-for-linux # add "secure": true to ~/.config/teams-for-linux/Preferences for camera to work
      (remmina.override { withKf5Wallet = false; })
      unstablePkgs.lmstudio
      unstablePkgs.winboat
    ];
  };
}
