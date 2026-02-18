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
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.zathura = {
      enable = true;
    };
  });
}
