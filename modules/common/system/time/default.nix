{ lib, config, ... }:
let
  cfg = config.local.system.time;
in
{
  options.local.system.time = {
    ntp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable NTP time synchronization";
      };

      server = lib.mkOption {
        type = lib.types.str;
        default = "pool.ntp.org";
        description = "NTP server to use for time synchronization";
      };
    };

    location = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Brussels";
      description = "Timezone location";
    };
  };

  config = {
    time.timeZone = "${cfg.location}";
  };
}
