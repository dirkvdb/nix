{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.qgis;
  user = config.local.user;
in
{
  options.local.apps.qgis = {
    enable = lib.mkEnableOption "qgis";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qgis ];

    home-manager.users.${user.name} = {
      xdg.mimeApps.defaultApplications = {
        "application/x-esri-shape" = "org.qgis.qgis.desktop";
        "image/tiff" = "org.qgis.qgis.desktop";
        "image/x-tiff" = "org.qgis.qgis.desktop";
        "application/geopackage+sqlite3" = "org.qgis.qgis.desktop";
      };
    };
  };
}
