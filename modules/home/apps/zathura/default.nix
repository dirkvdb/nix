{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.zathura;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.zathura = {
    enable = lib.mkEnableOption "PDF viewer";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "application/pdf"
      ];
      description = "MIME types for which Zathura is the default handler.";
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.zathura = {
      enable = true;
    };

    xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "org.pwmt.zathura.desktop");
  });
}
