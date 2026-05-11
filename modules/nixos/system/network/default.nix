{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network;
in
{
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
