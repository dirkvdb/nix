{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.waydroid;
in
{
  options.local.apps.waydroid = {
    enable = lib.mkEnableOption "waydroid";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = lib.mkDefault pkgs.waydroid-nftables;
  };
}
