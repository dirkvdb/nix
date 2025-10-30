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
    ../../core/default.nix
    ../../modules/nixos/import.nix
    ../../modules/common/import.nix

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
        home-manager.enable = false;
        shell.package = pkgs.fish;
      };

      system = {
        nix = {
          unfree.enable = true;
          nh.enable = true;
          flakes.enable = true;
        };

        boot = {
          systemd = {
            enable = true;
            graphical = true;
          };
        };

        audio.pipewire.enable = true;
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

        utils = {
          dev = true;
          sysadmin = true;
        };

        bluetooth.enable = true;
        fonts.enable = true;
      };

      services = {
        ssh.enable = true;
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
    };

    nixCfg.applications.enable = true;
    nixCfg.applications.gui = true;
    nixCfg.configuration.enable = true;
    nixCfg.desktop.enable = true;

    services = {
      printing.enable = true;

      greetd = {
        enable = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
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
