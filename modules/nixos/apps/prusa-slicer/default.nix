{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.prusa-slicer;

in
{
  options.local.apps.prusa-slicer = {
    enable = lib.mkEnableOption "prusa-slicer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prusa-slicer
    ];
  };
}
