{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.mqtt;
in
{
  options.local.apps.mqtt = {
    enable = lib.mkEnableOption "MQTT visualization tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mqtt-explorer
    ];
  };
}
