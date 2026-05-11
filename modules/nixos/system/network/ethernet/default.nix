{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network.ethernet;
  net = config.local.system.network;
in
{
  options.local.system.network.ethernet = {
    enable = lib.mkEnableOption "Enable ethernet networking";

    dhcp = lib.mkOption {
      type = lib.types.enum [
        "ipv4"
        "ipv6"
        "yes"
        "no"
      ];
      default = "ipv4";
      description = "DHCP configuration for the ethernet interface";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network.networks."10-lan" = {
      matchConfig.Name = net.interface;
      networkConfig.DHCP = cfg.dhcp;
    };

    assertions = [
      {
        assertion = net.interface != null;
        message = "local.system.network.interface must be set when ethernet is enabled";
      }
    ];
  };
}
