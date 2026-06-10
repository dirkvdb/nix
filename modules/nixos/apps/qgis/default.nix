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

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "application/x-esri-shape"
        "image/tiff"
        "image/x-tiff"
        "application/geopackage+sqlite3"
      ];
      description = "MIME types for which QGIS is the default handler.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qgis ];

    home-manager.users.${user.name} = {
      xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "org.qgis.qgis.desktop");
    };
  };
}
