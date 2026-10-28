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
    ./freeze-diagnostics.nix
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

    programs.librepods.enable = true;
    users.users.dirk.openssh.authorizedKeys.keys = [
      "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4oqfUXoR8JbTTg8dY00q4ScAvCDje2n/KGnkahHsJ7 mediastation-mini-monitor"
    ];
    users.users.dirk.extraGroups = [
      "librepods"
      "vboxusers"
    ];
    virtualisation.virtualbox.host.enable = true;

    home-manager.users.dirk.systemd.user.services.librepods = {
      Unit = {
        Description = "LibrePods";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.librepods}/bin/librepods --headless";
        Environment = [
          "QT_LOGGING_RULES=openpods.debug=false"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    stylix = {
      enable = true;
    };

    # Apple Magic Trackpad driver and BlueZ's userspace HID transport.
    boot.kernelModules = [
      "hid_magicmouse"
      "uhid"
    ];

    # Boot display: match HDMI resolution to avoid scaling issues on fbcon
    boot.kernelParams = [
      "fbcon=nodefer"
      "initcall_blacklist=simpledrm_platform_driver_init"
      # DC_SKIP_DETECTION_LT: HPD detection retrains sleeping DP links and wakes
      # the Dell U2725QE backlight. Skip detection-time training, not normal wake.
      "amdgpu.dcdebugmask=0x200000"
      # GFXOFF-off trial: clear only 0x8000 from the observed 7.2.10 mask
      # 0xfff7bfff. Recheck the default mask when changing kernels.
      "amdgpu.ppfeaturemask=0xfff73fff"
    ];

    nix = {
      sshServe = {
        enable = true;
        protocol = "ssh-ng";
        write = true;
        trusted = true;
        # The MacBook's Nix daemon authenticates with its SSH host key.
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1tvupf77szfF11bL78JNIIAG0HX29e8ofXxmQlqU7g"
        ];
      };

    };

    services.udev.packages = with pkgs; [
      platformio-core.udev
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
        kernel = {
          cachyos.enable = false;
          useLatest = true;
        };

        cpu.cores = 20;
        performance.enable = true;
        binfmt.enable = true;

        nix = {
          armCache.enable = true;
          ld.enable = true;
        };

        boot = {
          secureboot.enable = true;
          graphical = true;
        };

        loginmanager.sddm = {
          enable = true;
          autologin.enable = true;
          display = "DP-3";
        };

        input.keyboard.via = true;

        audio.pipewire = {
          enable = true;
          airplay = false;
        };

        video.amd.enable = true;
        display.brightnesscontrol = {
          enable = true;
          i2cDevice = "i2c-13";
          # Dell U2725QE fails the ddcci driver's identification probe with
          # the default 60ms delay (dmesg: "core device probe failed: -19"),
          # even though ddcutil communicates with it over DDC/CI just fine.
          delay = 200;
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
          pac.enable = false;
        };
        officework = {
          enable = true;
          autostart = false;
        };
      };

      desktop = {
        enable = true;
        displayScale = 1.666667;
        noctalia.enable = true;
      };

      apps = {
        aichat.enable = true;
        celluloid.enable = true;
        chatgpt.enable = true;
        bitwarden.enable = true;
        direnv.enable = true;
        spotifast.enable = true;
        fladder.enable = true;
        ghostty.enable = true;
        herdr.enable = true;
        keepassxc = {
          enable = true;
          databasePaths = [
            "${config.local.services.syncthing.shares.secretsPath}/Desktop.kdbx"
          ];
          keyfilePath = "${config.local.user.homeDir}/.local/share/desktop.key";
        };

        localsend.enable = true;
        moonlight.enable = true;
        mqtt.enable = true;
        solidcraft.enable = true;
        topq.enable = true;
        neovim.enable = true;
        obsidian = {
          enable = true;
          vaults.notes = "Documents/Notes";
        };
        opencode.enable = true;
        onlyoffice.enable = true;
        panda-reader.enable = true;
        prusa-slicer.enable = true;
        qgis.enable = true;
        voxtype.enable = true;
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
        slack.enable = true;
        sops.enable = true;
        spotify.enable = true;
        teams.enable = true;
        tether.enable = true;
        vscode.enable = true;
        whatsapp.enable = true;
        winboat.enable = true;
        wine.enable = true;
        zathura.enable = true;
        zed = {
          enable = true;
          useLatestUpstream = true;
          localModels = true;
        };
        zellij.enable = true;

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
        allowedOrigins = [
          "http://mini.fritz.box:13305"
          "https://ai.hl.vandenboer.eu/"
        ];
        recipeOptions."builtin.qwen3.6-moe-35b-a3b-FLM" = {
          ctx_size = 65536;
          flm_args = "--prefill-chunk-len 8192";
        };
        customModels."Qwen3.8-27B-GGUF-UD-Q4_K_XL" = {
          checkpoints = {
            main = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
            mmproj = "unsloth/Qwen3.8-27B-GGUF:mmproj-BF16.gguf";
          };
          recipe = "llamacpp";
          recipe_options = {
            ctx_size = 32768;
            llamacpp_backend = "vulkan";
          };
          labels = [
            "custom"
            "chat"
            "tool-calling"
            "vision"
            "mtp"
          ];
          size = 17.2;
        };
        models = [
          "Qwen3.8-27B-GGUF-UD-Q4_K_XL"
          "qwen3.6-moe-35b-a3b-FLM"
          "qwen3.8-mtp-27b-FLM"
          # Small, fast model for simple prompts and lightweight agent tasks.
          "Qwen3.5-4B-MTP-GGUF"
        ];
      };
    };

    environment.systemPackages = with pkgs; [
      appimage-run
      freecad
      gliff
      gnumeric
      orca-slicer
      orrery
      unstablePkgs.ferdium
      unstablePkgs.freetube
      unstablePkgs.openscad
      unstablePkgs.openlogi
    ];
  };
}
