{
  lib,
  config,
  pkgs,
  ...
}:
let
  withUtils = config.local.system.utils.enable;
  cfg = config.local.system.utils;
  sysadmin = [ ];
in
{
  config = lib.mkIf withUtils {
    environment.systemPackages =
      with pkgs;
      [
        btop
      ]
      ++ lib.optionals cfg.sysadmin sysadmin;
  };
}
