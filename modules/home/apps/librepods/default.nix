{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.librepods;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.librepods = {
    enable = lib.mkEnableOption "Librepods application";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    home.packages = [ pkgs.librepods ];
  });
}
