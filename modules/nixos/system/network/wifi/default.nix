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

    firewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;
    networking.useNetworkd = true;
    networking.wireless.iwd.enable = true;
    networking.wireless.iwd.settings = {
      Settings = {
        AutoConnect = true;
      };
    };

    systemd.network.networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
      networkConfig.DHCP = "yes";
    };

    networking.firewall.enable = cfg.firewall;

    environment.systemPackages = with pkgs; [
      impala # wifi menu
    ];
  };
}
