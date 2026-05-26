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
    wakeOnLan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Wake-on-LAN for the ethernet interface";
    };
    interface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Name of the ethernet interface (required for Wake-on-LAN)";
      example = "enp3s0";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.interfaces = lib.mkIf (cfg.wakeOnLan && cfg.interface != null) {
      ${cfg.interface}.wakeOnLan.enable = true;
    };

    assertions = [
      {
        assertion = !cfg.wakeOnLan || cfg.interface != null;
        message = "local.system.network.interface must be set when wakeOnLan is enabled";
      }
    ];

    systemd.network = {
      enable = true;
      # Do not block boot/login waiting for full network online state.
      wait-online.enable = false;
    };

    networking = {
      useNetworkd = true;
      hostName = cfg.hostname;
      firewall.enable = cfg.firewall;
    };

    services.resolved = {
      enable = true;
      settings.Resolve.LLMNR = "false";
      settings.Resolve.MulticastDNS = "yes";
    };
  };
}
