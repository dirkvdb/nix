{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  inherit (config.lib.stylix) colors;
  cfg = config.local.apps.ghostty;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.ghostty = {
    enable = lib.mkEnableOption "Ghostty terminal emulator";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.ghostty = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

      settings = {
        theme = theme.ghosttyTheme;

        # base0D is neutral for UI accents; ANSI blue must remain distinct
        # from the foreground so directories (ls/lsd) are recognizable.
        palette = with colors.withHashtag; [
          "4=${base0E}"
          "12=${base0E}"
        ];

        # Font
        font-family = theme.terminalFont;
        font-style = "Regular";
        font-size = theme.terminalFontSize;

        keybind = [
          "ctrl+shift+h=previous_tab"
          "ctrl+shift+l=next_tab"
        ];

        # Scrollback
        scrollback-limit = 1000000000; # ~1GB

        # Window
        clipboard-paste-protection = false;
        window-padding-x = 14;
        window-padding-y = 14;
        confirm-close-surface = false;
        resize-overlay = "never";

        # Cursor stlying
        cursor-style = "block";
        cursor-style-blink = false;
        shell-integration-features = "no-cursor";
      };
    };
  });
}
