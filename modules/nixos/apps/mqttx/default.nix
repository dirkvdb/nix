{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.mqttx;
in
{
  options.local.apps.brave = {
    enable = lib.mkEnableOption "MQTT visualization tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mqttx
    ];
  };
}
