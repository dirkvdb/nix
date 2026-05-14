{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network.vpn;
in
{
  options.local.system.network.vpn.wireguard = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          sopsSecret = lib.mkOption {
            type = lib.types.str;
            description = "Sops secret key containing the wg-quick configuration file";
            example = "vpn/nordvpn-nl.conf";
          };

          autostart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Automatically start this VPN at boot. When false, manage manually via systemctl start/stop wg-quick-<name>.";
          };
        };
      }
    );
    default = { };
    description = "Named WireGuard VPN connections managed via wg-quick, for use with systemd-networkd.";
    example = {
      nordvpn-nl.sopsSecret = "vpn/nordvpn-nl.conf";
      nordvpn-be.sopsSecret = "vpn/nordvpn.conf";
    };
  };

  config = lib.mkIf (cfg.wireguard != { }) {
    sops.secrets = lib.mapAttrs' (name: wgCfg: lib.nameValuePair wgCfg.sopsSecret { }) cfg.wireguard;

    networking.wg-quick.interfaces = lib.mapAttrs (name: wgCfg: {
      configFile = config.sops.secrets.${wgCfg.sopsSecret}.path;
      autostart = wgCfg.autostart;
    }) cfg.wireguard;

    # Required so that WireGuard traffic is not dropped by reverse-path filtering
    networking.firewall.checkReversePath = "loose";
  };
}
