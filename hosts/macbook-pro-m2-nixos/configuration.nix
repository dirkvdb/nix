{
  pkgs,
  inputs,
  config,
  lib,
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
          networkmanager = {
            enable = true;
            vpn = {
              enable = true;
              nordvpn = true;
            };
          };
        };

        # network = {
        #   enable = true;
        #   hostname = "macbook-pro";

        #   wifi = {
        #     enable = true;
        #   };
        # };

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
        direnv.enable = true;
        mqtt.enable = true;
        foliate.enable = true;
        localsend.enable = true;
        neovim.enable = true;
        vscode.enable = true;
        vlc.enable = true;
        zathura.enable = true;
        zellij.enable = true;
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
    hardware.asahi.peripheralFirmwareDirectory = ./firmware;

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
            syma (tap-hold-release 200 200 a (layer-while-held symbols))
            symsemi (tap-hold-release 200 200 ; (layer-while-held symbols))
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

    environment.systemPackages = with pkgs; [
      teams-for-linux
      vulkan-tools
      brightnessctl
      asahi-audio # belongs to the workaround below
    ];

    # workaround for audio volume not restoring on reboot (https://github.com/nix-community/nixos-apple-silicon/issues/352)
    services.pipewire.configPackages = lib.mkForce [ ];
    services.pipewire.wireplumber.configPackages = lib.mkForce [ ];
  };
}
