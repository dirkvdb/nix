{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.topq;
  jsonFormat = pkgs.formats.json { };
  themeFamily = builtins.fromJSON (builtins.readFile ../../../../configs/themes/charcoal-grove.json);
  topqTheme = import ../../../../configs/themes/zed-to-gpui-kit.nix themeFamily;
in
{
  options.local.apps.topq = {
    enable = lib.mkEnableOption "Topq MQTT explorer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.topq ];

    home-manager.users.${config.local.user.name}.xdg.configFile = {
      "topq/config.json".source = jsonFormat.generate "topq-config.json" {
        light_theme = "Charcoal Grove Light";
        dark_theme = "Charcoal Grove";
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
      "topq/themes/charcoal-grove.json".source = jsonFormat.generate "topq-charcoal-grove.json" topqTheme;
    };
  };
}
