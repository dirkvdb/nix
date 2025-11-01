{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.services.aerospace;
in
{
  options.local.services.aerospace = {
    enable = lib.mkEnableOption "Enable aerospace tiling window manager";
  };

  config = lib.mkIf cfg.enable {
    services.aerospace = {
      enable = false;
      settings = pkgs.lib.importTOML ../../configs/aerospace.toml;
    };

    homebrew = {
      taps = [
        "FelixKratz/formulae"
      ];

      brews = [
        "borders" # from tap: FelixKratz/formulae
      ];
    };
  };
}
