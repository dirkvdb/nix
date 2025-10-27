{
  pkgs,
  lib,
  userConfig,
  ...
}:
{
  # Auto upgrade nix package and the daemon service.
  nix = {
    enable = true;
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "root"
        "${userConfig.username}"
      ];

    };

    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 1w";
    };

    optimise.automatic = true;
  };

  # Fix GID mismatch for nixbld group: remove on next clean install
  ids.gids.nixbld = 350;

  # targets.darwin.linkApps.enable = true;
  # targets.darwin.copyApps.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.hostName = userConfig.hostname;
  networking.computerName = userConfig.hostname;

  users.users."${userConfig.username}" = {
    home = "/Users/${userConfig.username}";
    description = userConfig.username;
    shell = "/etc/profiles/per-user/${userConfig.username}/bin/fish";
  };

  ###################################################################################
  #  macOS's System configuration
  #
  #  All the configuration options are documented here:
  #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
  #  and see the source code of this project to get more undocumented options:
  #    https://github.com/rgcr/m-cli
  ###################################################################################
  system = {
    stateVersion = 6;
    primaryUser = "${userConfig.username}";

    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    #activationScripts.postUserActivation.text = ''
    # activateSettings -u will reload the settings from the database and apply them to the current session,
    # so we do not need to logout and login again to make the changes take effect.
    #  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    #'';

    keyboard = {
      enableKeyMapping = true; # enable key mapping so that we can use `option` as `control`
      remapCapsLockToEscape = false; # remap caps lock to escape, useful for vim users
      swapLeftCommandAndLeftAlt = false;
    };

    defaults = {
      smb.NetBIOSName = userConfig.hostname;

      dock = {
        autohide = true;
        orientation = "bottom";
        show-recents = false; # disable recent apps
        static-only = false;
      };

      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true;
        QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true;
        ShowStatusBar = true; # show status bar
        FXEnableExtensionChangeWarning = false;
      };

      NSGlobalDomain = {
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        "com.apple.keyboard.fnState" = true; # enable function keys
        "com.apple.swipescrolldirection" = true; # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key

        # AppleInterfaceStyle = "Dark"; # dark mode
        ApplePressAndHoldEnabled = false; # enable press and hold

        InitialKeyRepeat = 15; # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # sets how fast it repeats once it starts.
        KeyRepeat = 3; # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)

        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution
        NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction
        NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      trackpad = {
        Clicking = true; # enable tap to click()
        TrackpadRightClick = true; # enable two finger right click
        TrackpadThreeFingerDrag = false; # enable three finger drag
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      #
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.ImageCapture".disableHotPlug = true;
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = false; # show full name in login window
      };
    };
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/src/github.com/evantravers/dotfiles/nix-darwin-configuration";

  programs.fish.enable = true;
  environment.shells = [
    pkgs.fish
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    gnupg.agent.enable = true;
    zsh.enable = true;
  };

  fonts.packages = with pkgs; [
    monaspace
    cascadia-code
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.caskaydia-mono
  ];

  environment = {
    variables.EDITOR = "micro";
    # variables.XDG_CONFIG_HOME = "${config.xdg.configHome}";

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [
      home-manager
      raycast
    ];
  };

  services.aerospace = {
    enable = false;
    settings = pkgs.lib.importTOML ../../configs/aerospace.toml;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };

    masApps = {
      Amphetamine = 937984704;
      Pages = 409201541;
      Numbers = 409203825;
    };

    # taps = [
    #   "FelixKratz/formulae"
    # ];

    # brews = [
    #   "borders" # from tap: FelixKratz/formulae
    # ];

    casks = [
      # Not available for macOS in nixpkgs:
      # balenaetcher
      # bruno
      "ghostty"
      "vivaldi"
      "fork"
      "localsend"
      "microsoft-teams"
      "microsoft-outlook"
      "microsoft-excel"
      "microsoft-auto-update"
      "orbstack"
      #"qgis"
      # autodesk-fusion
      "raycast"
      "spotify"
      "whatsapp"
      "zen"
    ];
  };
}
