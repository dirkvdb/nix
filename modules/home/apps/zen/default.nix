{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home-manager.users.${user.name} = lib.mkIf isLinux {
    programs.zen-browser = {
      enable = true;

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

      profiles.default = {
        isDefault = true;
        settings = {
          "zen.tabs.show-newtab-vertical" = false;
          "zen.theme.gradient" = true;
          "zen.theme.gradient.show-custom-colors" = false;
          "zen.theme.accent-color" = "AccentColor";
          "zen.urlbar.behavior" = "float";
          "zen.view.compact.enable-at-startup" = true;
          "zen.view.compact.hide-tabbar" = false;
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
  };
}
