{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.bluetooth;
in
{
  options.local.system.bluetooth = {
    enable = lib.mkEnableOption "Enable bluetooth support";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      overskride
    ];
  };
}
