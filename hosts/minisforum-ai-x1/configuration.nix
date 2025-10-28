{ pkgs, userConfig, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Common system applications
    ../../core/applications.nix
    # System configuration
    ../../core/fonts.nix
    ../../core/linux/configuration.nix
    ../../core/linux/hyprland.nix
    ../../core/linux/audio.nix
    ../../core/linux/boot.nix
    ../../core/linux/desktop.nix
    ../../core/linux/bluetooth.nix
    ../../core/linux/ethernet.nix
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05"; # Version at install time, never change

  # Use the latest kernel from unstable (for better AMD CPU support)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixCfg.applications.gui = true;
  nixCfg.applications.dev = true;
  nixCfg.desktop.enable = true;
  nixCfg.graphicalBoot.enable = true;

  nixCfg.ethernet = {
    enable = true;
    interface = "enp195s0";
    wakeOnLan = true;
    dhcp = "ipv4";
  };

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
        rocmPackages.clr.icd
        vaapiVdpau
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
    rocmPackages.rocm-smi

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

    wl-clipboard
  ];

}
