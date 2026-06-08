# Home-manager module for the VITO VPN jumphost.
#
# Uses the vpn-jumphost flake (github:VITO-RMA/vpn-jumphost) which provides
# a single Rust binary (`jumphost`) that manages:
#   - F5 cookie validation and browser-based refresh (Chromium via CDP)
#   - openconnect + ocproxy lifecycle (userspace tunnel, no sudo)
#   - Routing SOCKS5 proxy (per-domain VPN-vs-direct routing)
#   - PAC HTTP server
#   - Sleep/wake detection and automatic reconnection
#
# Configuration is written to ~/.config/vpn-jumphost/config.toml.
# Credentials (username + password) are read from sops secrets:
#   /run/secrets/vpnjumphost/username
#   /run/secrets/vpnjumphost/password

{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:

let
  inherit (config.local) user;
  cfg = config.local.services.vpnjumphost;
  mkUserHome = mkHome user.name;

  usernameSecretPath = "/run/secrets/vpnjumphost/username";
  passwordSecretPath = "/run/secrets/vpnjumphost/password";

  # Build the TOML config file content.
  configContent = ''
    # VPN jumphost configuration — managed by NixOS
    # Do not edit manually; changes will be overwritten on rebuild.

    vpn_url = "${cfg.vpnUrl}"
    vpn_protocol = "${cfg.vpnProtocol}"
    socks_port = ${toString cfg.socksPort}
    ocproxy_keepalive = ${toString cfg.ocproxyKeepalive}
    check_interval = ${toString cfg.checkInterval}

    [domains]
    proxy = [${lib.concatMapStringsSep ", " (d: ''"${d}"'') cfg.domains.proxy}]
    direct = [${lib.concatMapStringsSep ", " (d: ''"${d}"'') cfg.domains.direct}]

    [credentials]
    username_file = "${usernameSecretPath}"
    password_file = "${passwordSecretPath}"
  '';

in
{
  options.local.system.network.proxy.pacUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "URL pointing to the PAC file. Set automatically when local.services.vpnjumphost.pac.enable is true.";
  };

  options.local.services.vpnjumphost = {
    enable = lib.mkEnableOption "VITO VPN jumphost (openconnect + ocproxy SOCKS5 userspace tunnel)";

    vpnUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://byod.vito.be";
      description = "F5 VPN endpoint URL.";
    };

    vpnProtocol = lib.mkOption {
      type = lib.types.str;
      default = "f5";
      description = "OpenConnect protocol identifier.";
    };

    socksPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "SOCKS5 listen port for ocproxy (upstream of routing proxy).";
    };

    ocproxyKeepalive = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "TCP keepalive interval (seconds) passed to ocproxy via -k.";
    };

    checkInterval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Seconds between periodic cookie validity checks.";
    };

    domains = {
      proxy = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "vito.be"
          "vito.local"
          "int.vito.be"
          "int.energyville.be"
        ];
        description = "Domains routed through the VPN tunnel.";
      };

      direct = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "byod.vito.be" ];
        description = "Domains that must always bypass the tunnel.";
      };
    };

    pac = {
      enable = lib.mkEnableOption "PAC proxy auto-configuration (served by the jumphost binary over HTTP)";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8091;
        description = "Port for the built-in PAC HTTP server.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        local.system.network.proxy.pacUrl =
          lib.mkIf cfg.pac.enable "http://127.0.0.1:${toString cfg.pac.port}/proxy.pac";
      }
      (mkUserHome {

        home.packages = [ pkgs.vpn-jumphost ];

        xdg.configFile."vpn-jumphost/config.toml" = {
          text = configContent;
        };

        systemd.user.services.vpn-jumphost = {
          Unit = {
            Description = "VPN jumphost (openconnect + ocproxy, supervised)";
            After = [
              "network-online.target"
              "graphical-session.target"
            ];
            Wants = [
              "network-online.target"
              "graphical-session.target"
            ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.vpn-jumphost}/bin/jumphost run --serve-pac";
            KillSignal = "SIGTERM";
            TimeoutStopSec = 15;
            Restart = "on-failure";
            RestartSec = 15;
            StartLimitIntervalSec = 600;
            StartLimitBurst = 3;
            # Allow time for browser-based MFA if cookie refresh is needed.
            TimeoutStartSec = 360;
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };

      })
    ]
  );
}
