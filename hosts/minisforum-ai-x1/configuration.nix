{
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
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "26.05"; # Version at install time, never change

    stylix = {
      enable = true;
    };

    # Use the latest kernel from unstable (for better AMD CPU support)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Boot display: match HDMI resolution to avoid scaling issues on fbcon
    boot.kernelParams = [
      "video=DP-3:1920x1080@60D"
      "video=HDMI-A-1:1920x1080@60D"
      "fbcon=nodefer"
      "initcall_blacklist=simpledrm_platform_driver_init"
    ];

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
          ld.enable = true;
        };

        boot = {
          secureboot.enable = true;
          graphical = true;
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
        hyprmoncfg.enable = true;
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
        syncthing = {
          enable = true;
          shares.secrets = true;
        };
        docker.enable = true;
        power-profiles-daemon.enable = true;
        vpnjumphost = {
          enable = true;
          autostart = false;
          pac.enable = true;
        };
        officework = {
          enable = true;
          autostart = false;
        };
      };

      desktop = {
        enable = true;
        displayScale = 1.666667;
        hyprland.enable = true;
      };

      apps = {
        aichat.enable = true;
        celluloid.enable = true;
        direnv.enable = true;
        fladder.enable = true;
        ghostty.enable = true;
        keepassxc = {
          enable = true;
          databasePaths = [
            "${config.local.services.syncthing.shares.secretsPath}/Desktop.kdbx"
          ];
          keyfilePath = "${config.local.user.homeDir}/.local/share/desktop.key";
        };
        librepods.enable = true;
        localsend.enable = true;
        moonlight.enable = true;
        mqtt.enable = true;
        neovim.enable = true;
        prusa-slicer.enable = true;
        qgis.enable = true;
        remmina = {
          enable = true;
          connections = {
            EISSDESK = {
              name = "EISSDESK";
              server = "eissdesk.vito.local";
              drive = "/work/transfer";
              protocol = "RDP";
              username = "vdboerd";
              password = ".";
              domain = "VITO";
              ignore-tls-errors = 1;
              proxy_type = "socks5";
              proxy_hostname = "127.0.0.1";
              proxy_port = 1080;
            };
          };
        };
        retro-emulation.enable = true;
        retro-emulation.eden.archnative = true;
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
          useLatestUpstream = true;
          localModels = true;
        };

      };
    };

    hardware.amd-npu = {
      enable = true;
      enableFastFlowLM = true; # LLM inference on NPU
      enableLemonade = true; # OpenAI-compatible API server
      enableROCm = true; # ROCm GPU backends (llamacpp + sd-cpp)
      enableVulkan = true; # Vulkan GPU backends (llamacpp + whispercpp)
      enableImageGen = true; # default true; set false to drop sd-cpp from closure
      lemonade = {
        user = config.local.user.name;
        host = "0.0.0.0";
      };
    };

    environment.systemPackages = with pkgs; [
      appimage-run
      gitcomet
      freecad
      gnumeric
      onlyoffice-desktopeditors
      orca-slicer
    ];
  };
}
