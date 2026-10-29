{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.map;
in
{
  options.local.apps.map.enable = lib.mkEnableOption "Map geospatial data viewer";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.map ];
  };
}
