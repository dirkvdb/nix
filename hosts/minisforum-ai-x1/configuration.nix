{
  pkgs,
  config,
  userConfig,
  inputs,
  ...
}:
let
  inherit (config.local) user;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Core aggregated modules
    ../../core/default.nix
    ../../modules/nixos/import.nix

    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.05"; # Version at install time, never change

    # Use the latest kernel from unstable (for better AMD CPU support)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    local = {
      system = {

        boot = {
          systemd = {
            enable = true;
            graphical = true;
          };
        };

        audio.pipewire.enable = true;
        video.amd.enable = true;

        network = {
          ethernet = {
            enable = true;
            wakeOnLan = true;
            interface = "enp195s0";
            dhcp = "ipv4";
          };
        };

        bluetooth.enable = true;
      };

      desktop = {
        hyprland.enable = true;
      };
    };

    nixCfg.applications.enable = true;
    nixCfg.applications.gui = true;
    nixCfg.applications.dev = true;
    nixCfg.fonts.enable = true;
    nixCfg.configuration.enable = true;
    nixCfg.docker.enable = true;
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
      virt-manager.enable = true;
      nix-ld.enable = true;
      # steam.enable = true;
      fish.enable = true;
      firefox.enable = true;
      localsend.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/${userConfig.username}/nix"; # sets NH_OS_FLAKE variable
      };

      # xfconf.enable = true; # for thunar settings
      # thunar.enable = true;
      # thunar.plugins = with pkgs.xfce; [
      #   thunar-archive-plugin
      #   thunar-volman
      # ];
    };

    environment.systemPackages = with pkgs; [
      gparted
      ghostty
      impala # wifi menu
      mako # notifications
      swayosd
      slack

      # works
      teams-for-linux

      #  Apps
      brightnessctl

      (btop.override {
        rocmSupport = true;
      })
    ];
  };
}
