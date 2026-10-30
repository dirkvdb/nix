{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.map;
  jsonFormat = pkgs.formats.json { };
  themeFamily = builtins.fromJSON (builtins.readFile ../../../../configs/themes/charcoal-grove.json);
  mapTheme = import ../../../../configs/themes/zed-to-gpui-kit.nix themeFamily;
in
{
  options.local.apps.map.enable = lib.mkEnableOption "Map geospatial data viewer";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.map ];

    home-manager.users.${config.local.user.name}.xdg.configFile = {
      "map/config.json".source = jsonFormat.generate "map-config.json" {
        light_theme = "Charcoal Grove Light";
        dark_theme = "Charcoal Grove";
      };
      "map/themes/charcoal-grove.json".source = jsonFormat.generate "map-charcoal-grove.json" mapTheme;
    };
  };
}
