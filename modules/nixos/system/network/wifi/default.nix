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
    networking.wireless.iwd.enable = true;
    networking.wireless.iwd.settings = {
      Settings = {
        AutoConnect = true;
      };
    };

    networking.firewall.enable = cfg.firewall;

    environment.systemPackages = with pkgs; [
      impala # wifi menu
    ];
  };
}
