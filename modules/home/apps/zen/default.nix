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
  isAarch64Linux = pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64;
  isDesktop = config.local.desktop.enable;
  keepassEnabled = config.local.apps.keepassxc.enable;
  mkUserHome = mkHome user.name;
  proxyPacUrl = config.local.system.network.proxy.pacUrl;

  # Widevine CDM plugin for Firefox-based browsers on aarch64-linux.
  # Symlinks the widevine-cdm package into the GMP plugin directory structure
  # that Firefox expects, so DRM-protected content (Netflix, Spotify, etc.) works.
  widevineGmp = pkgs.stdenv.mkDerivation {
    name = "widevine-firefox";
    version = pkgs.widevine-cdm.version;
    buildCommand = ''
      mkdir -p $out/gmp-widevinecdm/system-installed
      ln -s "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/manifest.json" $out/gmp-widevinecdm/system-installed/manifest.json
      ln -s "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm/_platform_specific/linux_arm64/libwidevinecdm.so" $out/gmp-widevinecdm/system-installed/libwidevinecdm.so
    '';
    meta = pkgs.widevine-cdm.meta // {
      platforms = [ "aarch64-linux" ];
    };
  };
in
{
  options.local.apps.zen = {
    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
        "application/xhtml+xml"
      ];
      description = "MIME types for which Zen Browser is the default handler.";
    };
  };

  config = lib.mkIf (isLinux && isDesktop) (mkUserHome {

    programs.zen-browser = {
      enable = true;

      nativeMessagingHosts = lib.optionals keepassEnabled [ pkgs.keepassxc ];

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
      }
      // lib.optionalAttrs (proxyPacUrl != null) {
        Proxy = {
          Mode = "autoConfig";
          AutoConfigURL = proxyPacUrl;
          Locked = true;
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
            "zen.urlbar.replace-newtab" = false;
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
          }
          // lib.optionalAttrs (proxyPacUrl != null) {
            "network.proxy.type" = 2;
            "network.proxy.autoconfig_url" = proxyPacUrl;
          }
          // {
            # Enable Widevine DRM support (Netflix, Disney+, Spotify, etc.)
            "browser.eme.ui.enabled" = true;
            "media.gmp-widevinecdm.visible" = true;
            "media.gmp-widevinecdm.enabled" = true;
            "media.eme.enabled" = true;
            "media.eme.encrypted-media-encryption-scheme.enabled" = true;
          }
          // lib.optionalAttrs isAarch64Linux {
            "media.gmp-widevinecdm.version" = "system-installed";
            "media.gmp-widevinecdm.autoupdate" = false;
          };
          search = {
            force = true;
            default = "google";
          };
        };
    };

    # Point Firefox GMP plugin path to our widevine derivation on aarch64-linux.
    # Set in both home.sessionVariables (shell logins) and systemd.user.sessionVariables
    # (graphical sessions launched via systemd/uwsm) so Zen can always find the CDM.
    home.sessionVariables = lib.mkIf isAarch64Linux {
      MOZ_GMP_PATH = "${widevineGmp}/gmp-widevinecdm/system-installed";
    };
    # systemd.user.sessionVariables = lib.mkIf isAarch64Linux {
    #   MOZ_GMP_PATH = "${widevineGmp}/gmp-widevinecdm/system-installed";
    # };

    stylix.targets.zen-browser.profileNames = [ "default" ];

    xdg.mimeApps.defaultApplications = lib.genAttrs config.local.apps.zen.mimeTypes (
      _: "zen-beta.desktop"
    );
  });
}
