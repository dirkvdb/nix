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
  });
}
