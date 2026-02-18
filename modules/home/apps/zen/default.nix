{
  config,
  pkgs,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  keepassEnabled = config.local.home-manager.keepassxc.enable;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf (isLinux && isDesktop) (mkUserHome {

    programs.zen-browser = {
      enable = true;
      suppressXdgMigrationWarning = true;

      nativeMessagingHosts = [ pkgs.firefoxpwa ];

      policies = {
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };

      profiles.default =
        let
          containers = {
            Personal = {
              color = "purple";
              icon = "fingerprint";
              id = 1;
            };
            Work = {
              color = "blue";
              icon = "briefcase";
              id = 2;
            };
          };
          spaces = {
            Personal = {
              id = "c6de089c-410d-4206-961d-ab11f988d40a";
              icon = "chrome://browser/skin/zen-icons/selectable/people.svg";
              container = containers.Personal.id;
              position = 1000;
            };
            Work = {
              id = "cdd10fab-4fc5-494b-9041-325e5759195b";
              icon = "chrome://browser/skin/zen-icons/selectable/briefcase.svg";
              container = containers.Work.id;
              position = 2000;
            };
          };

          pins = {
            # Personal
            gmail = {
              title = "Gmail";
              url = "https://mail.google.com/";
              id = "2884bea2-d686-42a4-a86d-567ed4582b7c";
              container = containers.Personal.id;
              workspace = spaces.Personal.id;
              position = 100;
              isEssential = true;
            };
            youtube = {
              title = "Youtube";
              url = "https://www.youtube.com/";
              id = "fd41d042-1e88-451e-9426-24ce1621b8c7";
              container = containers.Personal.id;
              workspace = spaces.Personal.id;
              position = 101;
              isEssential = true;
            };
            reddit = {
              title = "Reddit";
              url = "https://www.reddit.com/";
              id = "7c22eb73-9aed-4350-80b4-63740a153a6f";
              container = containers.Personal.id;
              workspace = spaces.Personal.id;
              position = 102;
              isEssential = true;
            };
            chatgpt = {
              title = "ChatGPT";
              url = "https://www.chatgpt.com/";
              id = "eca9b96a-78ca-4f1f-84f5-c738ff9ee886";
              container = containers.Personal.id;
              workspace = spaces.Personal.id;
              position = 103;
              isEssential = true;
            };
            # Work
            vitogit = {
              title = "Git";
              url = "https://git.vito.be/";
              id = "25b1ce57-bc9c-4f41-8737-222cbce11095";
              container = containers.Work.id;
              workspace = spaces.Work.id;
              position = 100;
              isEssential = true;
            };
            jira = {
              title = "Jira";
              url = "https://jira.vito.be/";
              id = "32c266a0-0ee0-41e5-90ca-6acff76f461b";
              container = containers.Work.id;
              workspace = spaces.Work.id;
              position = 101;
              isEssential = true;
            };
          };
        in
        {
          isDefault = true;
          containersForce = true;
          spacesForce = true;
          pinsForce = true;
          inherit containers pins spaces;

          settings = {
            "zen.tabs.show-newtab-vertical" = false;
            "zen.theme.gradient" = true;
            "zen.theme.gradient.show-custom-colors" = false;
            "zen.theme.accent-color" = "AccentColor";
            "zen.urlbar.behavior" = "float";
            "zen.view.compact.enable-at-startup" = true;
            "zen.view.compact.hide-tabbar" = true;
            "zen.view.compact.hide-toolbar" = true;
            "zen.view.compact.toolbar-flash-popup" = false;
            "zen.view.sidebar-expanded" = false;
            "zen.view.show-newtab-button-top" = false;
            "zen.view.window.scheme" = 2;
            "zen.ui.migration.compact-mode-button-added" = true;
            "zen.welcome-screen.seen" = true;
            "zen.workspaces.continue-where-left-off" = true;
            "sidebar.visibility" = "hide-sidebar";
            "browser.translations.neverTranslateLanguages" = "nl";
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.download.autohideButton" = true;
            "extensions.ui.dictionary.hidden" = true;
            "font.name.serif.x-western" = theme.uiFontSerif;
            "font.name.sans-serif.x-western" = theme.uiFont;
            "font.name.monospace.x-western" = theme.terminalFont;
            "font.size.variable.x-unicode" = theme.uiFontSize + 6;
            "font.size.variable.x-western" = theme.uiFontSize + 6;
          };
          search = {
            force = true;
            default = "google";
          };
        };
    };

    stylix.targets.zen-browser.profileNames = [ "default" ];

    home.file = lib.mkIf (keepassEnabled && isLinux) {
      ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text = builtins.toJSON {
        allowed_extensions = [
          "keepassxc-browser@keepassxc.org"
        ];

        description = "KeePassXC integration with native messaging support";
        name = "org.keepassxc.keepassxc_browser";
        path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
        type = "stdio";
      };
    };
  });
}
