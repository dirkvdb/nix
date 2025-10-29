{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network;
in
{
  options.local.system.network = {
    enable = lib.mkEnableOption "Enable networking";
    firewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable firewall";
    };
    hostname = lib.mkOption {
      type = lib.types.string;
      description = "Device hostname";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;
      # Do not block boot/login waiting for full network online state.
      wait-online.enable = false;
    };

    networking = {
      hostName = cfg.hostname;
      firewall.enable = cfg.firewall;
    };

    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      resolved.enable = true;
    };
  };
}
