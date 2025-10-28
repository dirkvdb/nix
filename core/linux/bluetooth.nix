{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nixCfg.bluetooth;
in
{

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      overskride
    ];
  };
}
