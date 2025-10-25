{pkgs, userConfig, ...}: {
  nix = {
    settings = {
      trusted-users = ["root" userConfig.username];
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
    ];
  };

  networking = {
    hostName = userConfig.hostname;
  };

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
      # AMD GPU tools
      radeontop
      clinfo
      vulkan-tools
      rocmPackages.rocm-smi

      #  Apps
      brightnessctl
      (btop.override {
        rocmSupport = true;
      })
      cpufrequtils
      curl
      fd
      glib # for gsettings to work
      gsettings-qt
      gtk-engine-murrine # for gtk themes
      killall
      wl-clipboard
      ripgrep
    ];

  system.stateVersion = "25.05"; # Did you read the comment?
}
