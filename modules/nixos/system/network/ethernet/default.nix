{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network.ethernet;
in
{
  options.local.system.network.ethernet = {
    enable = lib.mkEnableOption "Enable ethernet networking";
    interface = lib.mkOption {
      type = lib.types.str;
      description = "Name of the ethernet interface";
      example = "enp195s0";
    };

    wakeOnLan = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wake-on-LAN for the ethernet interface";
    };

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

    firewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;
      # Do not block boot/login waiting for full network online state.
      wait-online.enable = false;
    };

    networking = {
      firewall.enable = cfg.firewall;
      interfaces.${cfg.interface}.wakeOnLan.enable = cfg.wakeOnLan;
    };

    systemd.network.networks."10-lan" = {
      matchConfig.Name = cfg.interface;
      networkConfig.DHCP = cfg.dhcp;
    };

    assertions = [
      {
        assertion = cfg.interface != "";
        message = "nixCfg.ethernet.interface must be set (non-empty) when nixCfg.ethernet.enable is true";
      }
    ];
  };
}
