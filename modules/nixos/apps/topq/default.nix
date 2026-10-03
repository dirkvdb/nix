{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.topq;
in
{
  options.local.apps.topq = {
    enable = lib.mkEnableOption "Topq MQTT explorer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.topq ];
  };
}
