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

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
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
        audio.pipewire.enable = true;

        boot = {
          systemd = {
            enable = true;
            graphical = true;
          };
        };

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

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      # Networking
      resolved.enable = true;
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd # OpenCL ICD loader
          rocmPackages.rocm-smi # ROCm System Management Interface
          libva # Video Acceleration API
          libvdpau-va-gl
        ];
      };

      # AMD GPU firmware
      enableRedistributableFirmware = true;

      # CPU microcode updates
      cpu.amd.updateMicrocode = true;
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
      # AMD GPU tools
      radeontop
      clinfo
      vulkan-tools

      libva # VA-API

      gparted
      ghostty
      impala # wifi menu
      mako # notifications
      swayosd
      slack

      # graphics config Tools
      glxinfo # OpenGL info
      vulkan-tools # Khronos official Vulkan Tools and Utilities
      clinfo # Print information about available OpenCL platforms and devices
      libva-utils # Collection of utilities and examples for VA-API

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
