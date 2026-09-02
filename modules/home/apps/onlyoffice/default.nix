{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.onlyoffice;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless or false;
in
{
  options.local.apps.onlyoffice = {
    enable = lib.mkEnableOption "OnlyOffice Desktop Editors";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ];
      description = "MIME types for which OnlyOffice is the default handler.";
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless && pkgs.stdenv.isLinux) (mkUserHome {
    home.packages = [ pkgs.onlyoffice-desktopeditors ];

    xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (
      _: "onlyoffice-desktopeditors.desktop"
    );
  });
}
