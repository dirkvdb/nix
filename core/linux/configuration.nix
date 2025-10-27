{ pkgs, userConfig, ... }:
{
  nix = {
    settings = {
      trusted-users = [
        "root"
        userConfig.username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "23:30";
      options = "--delete-older-than +3";
    };
  };

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  # Define a user account.
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.username;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "hidraw"
      "i2c"
      "video"
    ];
  };
  users.groups.hidraw = { };

  networking = {
    hostName = userConfig.hostname;
  };

  hardware.i2c.enable = true;
  services.ddccontrol.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Brussels";

  i18n = {
    # Select internationalisation properties.
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "nl_BE.UTF-8";
      LC_IDENTIFICATION = "nl_BE.UTF-8";
      LC_MEASUREMENT = "nl_BE.UTF-8";
      LC_MONETARY = "nl_BE.UTF-8";
      LC_NAME = "nl_BE.UTF-8";
      LC_NUMERIC = "nl_BE.UTF-8";
      LC_PAPER = "nl_BE.UTF-8";
      LC_TELEPHONE = "nl_BE.UTF-8";
      LC_TIME = "nl_BE.UTF-8";
    };
  };

  security.rtkit.enable = true;
  services = {
    openssh.enable = true;
    resolved.enable = true; # Networking
    udev.extraRules = ''
      # Give group hidraw RW access to all hidraw devices (needed for via keyboards)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="hidraw"
      # Give access to i2c devices (needed for monitor brightness control)
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';
  };

  systemd.services.ddcci-attach-i2c13 = {
    description = "Attach ddcci driver to i2c-13 for external monitor backlight";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/i2c-13/new_device || true'";
    };
  };

  hardware = {
    bluetooth.enable = true;
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

  # systemd = {
  #   services = {
  #   };
  # };

  # enable containerization ( docker )
  virtualisation = {
    containers.enable = true;
    libvirtd = {
      enable = true;
    };
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  programs = {
    direnv.enable = true;
    virt-manager.enable = true;
    nix-ld.enable = true;
    # steam.enable = true;
    fish.enable = true;
    firefox.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    #  Apps
    cpufrequtils
    curl
    lazygit
    fd
    killall
    ripgrep
    brightnessctl
  ];
}
