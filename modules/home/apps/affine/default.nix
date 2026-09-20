{
  config,
  lib,
  mkHome,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.affine;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.affine.enable = lib.mkEnableOption "AFFiNE desktop app";

  config = lib.mkIf (cfg.enable && !config.local.headless) (mkUserHome {
    home.packages = [ pkgs.affine ];
  });
}
