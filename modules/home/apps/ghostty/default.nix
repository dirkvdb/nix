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
  cfg = config.local.home-manager.ghostty;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.home-manager.ghostty = {
    enable = lib.mkEnableOption "Ghostty terminal emulator";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.ghostty = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

      settings = {
        theme = theme.ghosttyTheme;

        # Font
        font-family = theme.terminalFont;
        font-style = "Regular";
        font-size = theme.terminalFontSize;

        # Window
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
