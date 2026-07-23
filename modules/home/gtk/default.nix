{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user theme;
  inherit (config.lib.stylix) colors;
  hasDesktop = config.local.desktop.enable or false;
  mkUserHome = mkHome user.name;

  # Fix Stylix-generated GTK button text being too dark on dark backgrounds.
  # Forces button labels to use the theme foreground color (base05).
  # For suggested-action (primary) buttons with a light background, use dark text.
  buttonCssFix = ''
    button {
      color: ${theme.uiTextColor};
    }
    button.suggested-action {
      color: #${colors.base00};
    }
  '';

  # Stylix's GTK target maps every "default text" role (window/view/headerbar/
  # sidebar/card/dialog/popover foreground) to base05, the same warm color
  # used for accent_color. Override those roles here so ordinary text and
  # symbolic icons use the cooler uiTextColor, while accent_color (buttons,
  # links, selections) keeps the warmer uiAccentColor as the true highlight.
  textColorCssFix = ''
    @define-color window_fg_color ${theme.uiTextColor};
    @define-color view_fg_color ${theme.uiTextColor};
    @define-color headerbar_fg_color ${theme.uiTextColor};
    @define-color sidebar_fg_color ${theme.uiTextColor};
    @define-color card_fg_color ${theme.uiTextColor};
    @define-color dialog_fg_color ${theme.uiTextColor};
    @define-color popover_fg_color ${theme.uiTextColor};
  '';
in
{
  config = lib.mkIf hasDesktop (mkUserHome {
    home.packages = with pkgs; [
      nwg-look # tool to inspect the gtk settings
    ];

    stylix.targets.gtk.extraCss = textColorCssFix + buttonCssFix;

    gtk = {
      enable = true;
    };
  });
}
