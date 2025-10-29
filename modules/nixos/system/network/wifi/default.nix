{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.local.system.network.wifi;
in
{
  options.local.system.network.wifi = {
    enable = lib.mkEnableOption "Enable wireless networking";
    interface = lib.mkOption {
      type = lib.types.str;
      description = "Name of the wifi interface";
      example = "wlan0";
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

    networking.firewall.enable = cfg.firewall;

    environment.systemPackages = with pkgs; [
      impala # wifi menu
    ];

    assertions = [
      {
        assertion = cfg.interface != "";
        message = "config.local.system.network.wifi.interface must be set (non-empty) when nixCfg.ethernet.enable is true";
      }
    ];
  };
}
