{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.wluma;
  mkUserHome = mkHome user.name;
in
{
  options.local.services.wluma = {
    enable = lib.mkEnableOption "wluma automatic brightness adjustment";

    alsIioPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the IIO ambient light sensor sysfs node.";
      example = "/sys/devices/platform/soc/2a6c00000.aop/als.1.auto";
    };

    alsThresholds = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Mapping of lux thresholds to brightness profile names.";
      default = {
        "0" = "night";
        "30" = "dim";
        "200" = "normal";
        "800" = "bright";
        "2500" = "outdoor";
      };
    };

    backlightName = lib.mkOption {
      type = lib.types.str;
      description = "Wayland output name for backlight control.";
      example = "eDP-1";
    };

    backlightPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the sysfs backlight device.";
      example = "/sys/class/backlight/apple-panel-bl";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = "Rust log level for the wluma service (e.g. debug, info, warn).";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    services.wluma = {
      enable = true;
      settings = {
        als.iio = {
          path = cfg.alsIioPath;
          thresholds = cfg.alsThresholds;
        };
        output.backlight = [
          {
            name = cfg.backlightName;
            path = cfg.backlightPath;
            capturer = "none";
          }
        ];
      };
    };

    systemd.user.services.wluma.Service.Environment = [ "RUST_LOG=${cfg.logLevel}" ];
  });
}
