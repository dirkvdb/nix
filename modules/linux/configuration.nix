{pkgs, userConfig, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./hyprland.nix
  ];

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

  # Use the latest kernel from unstable
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Define a user account.
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.username;
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  networking = {
    hostName = userConfig.hostname;
    networkmanager.enable = true;
    firewall.enable = false;
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

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.caskaydia-mono
      fira-code
      monaspace
      cascadia-code
    ];
  };

  security.rtkit.enable = true;
  services = {
    openssh.enable = true;
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
    };

    # Networking
    resolved.enable = true;
    blueman.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
    graphics.enable = true; # OpenGL
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
    steam.enable = true;
    fish.enable = true;
    firefox.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
      # Hyprland Stuff
      hypridle
      hyprpolkitagent
      pyprland
      #uwsm
      hyprlang
      hyprshot
      hyprcursor
      mesa
      nwg-displays
      nwg-look
      waypaper
      hyprland-qt-support # for hyprland-qt-support

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
