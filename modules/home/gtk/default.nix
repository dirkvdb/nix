{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.lib.stylix) colors;
  hasDesktop = config.local.desktop.enable or false;
  mkUserHome = mkHome user.name;

  # Fix Stylix-generated GTK button text being too dark on dark backgrounds.
  # Forces button labels to use the theme foreground color (base05).
  buttonCssFix = ''
    button {
      color: #${colors.base05};
    }
  '';
in
{
  config = lib.mkIf hasDesktop (mkUserHome {
    home.packages = with pkgs; [
      nwg-look # tool to inspect the gtk settings
    ];

    stylix.targets.gtk.extraCss = buttonCssFix;

    gtk = {
      enable = true;
    };
  });
}
