{
  pkgs,
  inputs,
  config,
  unstablePkgs,
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
  ];

  config = {
    system.stateVersion = "26.05"; # Version at install time, never change

    # Enable ZRAM for memory compression
    zramSwap = {
      enable = true;
      memoryPercent = 50; # Use up to 50% of RAM for compressed swap
      algorithm = "zstd"; # Modern, fast compression algorithm
    };

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
          ld.enable = true;
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
          networkmanager = {
            enable = true;
            vpn.homeVpn = true;
            wifi.backend = "wpa_supplicant";
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

        bluetooth.enable = true;
        fonts.enable = true;
      };

      services = {
        nordvpn = {
          enable = true;
          localDns = true;
        };
        hyprmoncfg.enable = true;
        ssh.enable = true;
        fwupd.enable = true;
        printing.enable = true;
        syncthing = {
          enable = true;
          shares.secrets = true;
        };
        power-profiles-daemon.enable = true;
        wluma = {
          enable = true;
          alsIioPath = "/sys/devices/platform/soc/2a6c00000.aop/als.1.auto";
          backlightName = "eDP-1";
          backlightPath = "/sys/class/backlight/apple-panel-bl";
          logLevel = "info";
        };
      };

      desktop = {
        enable = true;
        displayScale = 2.0;
        hyprland.enable = true;
      };

      apps = {
        celluloid.enable = true;
        direnv.enable = true;
        fladder.enable = true;
        mqtt.enable = true;
        foliate.enable = true;
        localsend.enable = true;
        moonlight.enable = true;
        neovim.enable = true;
        vscode.enable = true;
        zathura.enable = true;
        zed.enable = true;
        zellij.enable = false;
        sops = {
          enable = true;
          ageKeyFile = {
            path = "${user.homeDir}/.config/sops/age/keys.txt";
          };
        };
        ghostty.enable = true;
        teams.enable = true;
        keepassxc = {
          enable = true;
          databasePaths = [
            "${config.local.services.syncthing.shares.secretsPath}/Desktop.kdbx"
          ];
          keyfilePath = "${user.homeDir}/.local/share/desktop.key";
        };
      };
    };

    # Disable peripheral firmware extraction
    hardware.asahi.enable = true;
    hardware.asahi.peripheralFirmwareDirectory = ./firmware;

    # Inject ALS calibration firmware not handled by asahi-fwextract
    hardware.firmware = [
      (pkgs.runCommand "aop-als-cal-firmware" { } ''
        mkdir -p $out/lib/firmware/apple
        cp ${./firmware/aop-als-cal.bin} $out/lib/firmware/apple/aop-als-cal.bin
      '')
    ];

    # Swap fn and left ctrl keys on MacBook keyboard
    # fnmode=2 Use function keys by default
    boot.extraModprobeConfig = ''
      options hid-apple swap_fn_leftctrl=1
      options hid-apple swap_opt_cmd=1
      options hid_apple fnmode=2
      options appledrm show_notch=1
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

    # Remap Caps Lock to Escape (tap) / arrow layer (hold) using kanata (only for built-in keyboard)
    # The hardware address (2a9b30000) is stable for this M2 MacBook Pro model
    # If it changes on a different MacBook model, find it with:
    # ls -la /dev/input/by-path/ | grep kbd
    services.kanata = {
      enable = true;
      package = unstablePkgs.kanata;
      keyboards.default = {
        devices = [
          "/dev/input/by-path/platform-2a9b30000.input-event-kbd"
        ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps
            1 2 3 4 5 6 7 8 9 0
            q w e r t y u i o p
            a s d f g h j k l ; ' \
            z x c v b n m , . /
          )

          (deflayer base
            @cap
            1 2 3 4 5 6 7 8 9 0
            q w e r t y u i o p
            (chord chords a) s d f g h j k l (chord chords ;) ' \
            z x c v b n m , . /
          )

          (defchords chords 200
            (a ;) S-min
            (a) @syma
            (;) @symsemi
          )

          (defalias
            cap (tap-hold-release 200 200 esc (layer-while-held arrows))
            ;; tap: a    hold: symbols layer    early tap if same hand keys are pressed
            ;; other keys (like space) do NOT trigger early hold - waits for full timeout
            syma (tap-hold-tap-keys 200 200 a (layer-while-held symbols) (1 2 3 4 5 q w e r t s d f g z x c v b spc))
            ;; tap: ;    hold: symbols layer    early tap if same hand keys are pressed
            ;; other keys (like space) do NOT trigger early hold - waits for full timeout
            symsemi (tap-hold-tap-keys 200 200 ; (layer-while-held symbols) (6 7 8 9 0 y u i o p h j k l ' \ n m , . / spc))
          )

          (deflayer arrows
            _
            _ _ _ _ _ _ _ _ _ _
            _ _ _ _ _ _ _ _ _ _
            _ _ _ _ _ left down up rght _ _ _
            _ _ _ _ _ _ _ _ _ _
          )

          (deflayer symbols
            _
            _ _ _ _ _ _ _ _ _ _
            grv S-grv S-3 S-7 S-\ S-6 S-[ S-] [ ]
            S-min S-1 S-; = S-4 S-2 S-9 S-0 S-' S-min _ _
            S-5 S-/ S-8 S-= \ / - S-, S-. '
          )
        '';
      };
    };

    # The NixOS hardening default sets vm.mmap_rnd_bits=33, but the Apple Silicon
    # kernel only supports a maximum of 18 for this value on aarch64.
    boot.kernel.sysctl."vm.mmap_rnd_bits" = 18;

    environment.systemPackages = with pkgs; [
      decentpaste
      outlook-for-linux
      vulkan-tools
      brightnessctl
    ];
  };
}
