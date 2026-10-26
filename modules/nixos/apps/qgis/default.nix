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
        "application/x-qgis-project"
        "application/x-qgis-project-container"
        "application/x-esri-shape"
        "image/tiff"
        "image/x-tiff"
        "application/geopackage+sqlite3"
      ];
      description = "MIME types for which QGIS is the default handler.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.qgis
      (pkgs.writeTextDir "share/mime/packages/qgis-projects.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="application/x-qgis-project">
            <comment>QGIS project</comment>
            <sub-class-of type="application/xml"/>
            <glob pattern="*.qgs"/>
          </mime-type>
          <mime-type type="application/x-qgis-project-container">
            <comment>QGIS compressed project</comment>
            <sub-class-of type="application/zip"/>
            <glob pattern="*.qgz"/>
          </mime-type>
        </mime-info>
      '')
    ];

    home-manager.users.${user.name} = {
      xdg.mimeApps.associations.added = lib.genAttrs cfg.mimeTypes (_: "org.qgis.qgis.desktop");
      xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "org.qgis.qgis.desktop");
    };
  };
}
