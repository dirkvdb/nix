{
  lib,
  config,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.services.nordvpn;
  inherit (config.local) user;
  nordvpn = unstablePkgs.nordvpn;
in
{
  options.local.services.nordvpn = {
    enable = lib.mkEnableOption "NordVPN service with GUI";

    localDns = lib.mkEnableOption "Route .arr domains to the local DNS server (192.168.1.13), bypassing the VPN";
  };

  config = lib.mkIf cfg.enable {
    # Create dedicated nordvpn user and group
    users.users.nordvpn = {
      description = "User that runs nordvpnd";
      group = "nordvpn";
      isSystemUser = true;
    };
    users.groups.nordvpn = { };

    # Add user to nordvpn group so they can interact with the daemon
    users.users.${user.name}.extraGroups = [ "nordvpn" ];

    # nordvpnd uses systemd-resolved to configure DNS
    services.resolved.enable = true;

    # Allow nordvpn group to configure DNS servers via resolved
    security.polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.resolve1.set-dns-servers"
              && subject.isInGroup("nordvpn")) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    # Required so VPN traffic is not dropped by reverse-path filtering
    networking.firewall.checkReversePath = "loose";

    environment.systemPackages = [ nordvpn ];

    systemd.services.nordvpnd = {
      after = [ "network-online.target" ];
      requires = [ "nordvpnd.socket" ];
      description = "NordVPN daemon.";
      path = with unstablePkgs; [
        e2fsprogs
        iproute2
        iptables
        libxslt
        procps
        wireguard-tools
        nordvpn
      ];
      serviceConfig = {
        AmbientCapabilities = "CAP_NET_ADMIN";
        CapabilityBoundingSet = "CAP_NET_ADMIN";
        ExecStart = lib.getExe' nordvpn "nordvpnd";
        Group = "nordvpn";
        KillMode = "process";
        NonBlocking = true;
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "nordvpn";
        RuntimeDirectoryMode = "0750";
        StateDirectory = "nordvpn";
        StateDirectoryMode = "0750";
        User = "nordvpn";
      };
      wantedBy = [ "default.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.sockets.nordvpnd = {
      description = "NordVPN Daemon Socket";
      listenStreams = [ "/run/nordvpn/nordvpnd.sock" ];
      partOf = [ "nordvpnd.service" ];
      socketConfig = {
        DirectoryMode = "0750";
        NoDelay = true;
        SocketGroup = "nordvpn";
        SocketMode = "0770";
        SocketUser = "nordvpn";
      };
      wantedBy = [ "sockets.target" ];
    };

    # Route .arr queries to the local DNS server instead of the VPN's DNS.
    # Global resolved config uses the system routing table (not a specific link)
    # so packets reach 192.168.1.13 via the physical interface.
    services.resolved.settings = lib.mkIf cfg.localDns {
      Resolve = {
        DNS = "192.168.1.13";
        Domains = "~arr";
      };
    };

    # Always enable LAN discovery so local network services remain
    # reachable while the VPN is active.
    systemd.services.nordvpn-settings = {
      description = "Apply NordVPN settings";
      after = [ "nordvpnd.service" ];
      requires = [ "nordvpnd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "HOME=/tmp";
      };
      script =
        let
          nordvpnExe = lib.getExe' nordvpn "nordvpn";
        in
        ''
          # wait for the daemon to be ready
          for i in $(seq 1 10); do
            ${nordvpnExe} status >/dev/null 2>&1 && break
            sleep 1
          done
          ${nordvpnExe} set lan-discovery on || true
        '';
    };

    systemd.user.services.norduserd = {
      after = [ "network-online.target" ];
      description = "NordUserD Service";
      serviceConfig = {
        ExecStart = lib.getExe' nordvpn "norduserd";
        NonBlocking = true;
        Restart = "on-failure";
        RestartSec = 5;
      };
      wantedBy = [ "graphical-session.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
