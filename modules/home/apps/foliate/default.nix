{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.foliate;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.foliate = {
    enable = lib.mkEnableOption "Ebook reader";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "application/epub+zip"
        "application/x-fictionbook+xml"
        "application/x-mobipocket-ebook"
        "application/vnd.comicbook+zip"
        "application/vnd.comicbook-rar"
      ];
      description = "MIME types for which Foliate is the default handler.";
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.foliate = {
      enable = true;

      settings = {
        "viewer/view" = {
          animated = false;
          autohide-cursor = true;
          max-column-count = 1;
        };
        "viewer/font" = {
          minimum-size = 14;
        };
      };
    };

    xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (
      _: "com.github.johnfactotum.Foliate.desktop"
    );
  });
}
