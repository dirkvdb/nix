{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.solidcraft;
in
{
  options.local.apps.solidcraft.enable = lib.mkEnableOption "Solidcraft CAD application";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.solidcraft ];
    local.apps.mcp.solidcraft.enable = lib.mkDefault true;
  };
}
