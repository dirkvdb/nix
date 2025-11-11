{
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.local.system.defaults;
in
{
  options.local.system.defaults = {
    enable = mkEnableOption "Enable defaults configs";
  };

  config = mkIf cfg.enable {
    system = {
      keyboard = {
        enableKeyMapping = true; # enable key mapping so that we can use `option` as `control`
        remapCapsLockToEscape = false; # remap caps lock to escape, useful for vim users
        swapLeftCommandAndLeftAlt = false;
        swapLeftCtrlAndFn = true;
      };

      defaults = {
        smb.NetBIOSName = config.local.system.network.hostname;

        dock = {
          autohide = true;
          autohide-time-modifier = 0.25; # speed up autohide/show animation
          orientation = "bottom";
          show-recents = false; # disable recent apps
          static-only = false;

          persistent-apps = [
            "/Applications/Ghostty.app"
            "/Applications/Zen.app"
            "/Applications/Zed.app"
            "/Applications/Visual Studio Code.app"
            "/Applications/Fork.app"
            "/Applications/Whatsapp.app"
          ];
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
  };
}
