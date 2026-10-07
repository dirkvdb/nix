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

    home-manager.users.${config.local.user.name}.xdg.configFile."topq/config.json".text =
      builtins.toJSON {
        connections = [
          {
            name = "NAS";
            connection = "mqtts://iot@mqtt.lan:8883";
            client_id = "topq-${config.local.system.network.hostname}";
            topics = [
              {
                topic = "#";
                qos = 0;
              }
            ];
            validate_certificate = true;
          }
        ];
        active_connection = "NAS";
      };
  };
}
