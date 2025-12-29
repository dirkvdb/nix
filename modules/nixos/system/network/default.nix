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
      type = lib.types.nullOr lib.types.str;
      default = null;
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
        publish = {
          enable = true;
          domain = true;
          addresses = true;
          workstation = true;
        };
      };

      resolved = {
        enable = true;
        llmnr = "false"; # optional, but avoids conflicts
      };
    };
  };
}
