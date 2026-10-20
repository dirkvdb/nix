{
  config,
  lib,
  pkgs,
  ...
}:
let

  # Filter before Podman's DNAT bypasses the host INPUT chain.
  proxyIngressRule = "! -i lo -m addrtype --dst-type LOCAL -p tcp --dport 42617 -m iprange ! --src-range 192.168.1.13-192.168.1.14 -j DROP";
in
{
  imports = [ ../homepage.nix ];

  options.quadlets.zeroclaw.enable = lib.mkEnableOption "the ZeroClaw agent runtime Podman Quadlet";

  config = lib.mkIf config.quadlets.zeroclaw.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 42617 ];

    systemd.services.zeroclaw-proxy-filter = {
      description = "Restrict ZeroClaw ingress to its reverse proxy";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "zeroclaw-proxy-filter-start" ''
          set -eu
          ${pkgs.iptables}/bin/iptables -w -t mangle -C PREROUTING ${proxyIngressRule} 2>/dev/null || \
            ${pkgs.iptables}/bin/iptables -w -t mangle -A PREROUTING ${proxyIngressRule}
        '';
        ExecStop = pkgs.writeShellScript "zeroclaw-proxy-filter-stop" ''
          ${pkgs.iptables}/bin/iptables -w -t mangle -D PREROUTING ${proxyIngressRule} || true
        '';
      };
    };

    services.homepage-dashboard.quadletEntries.ZeroClaw = {
      href = "https://zeroclaw.hl.vandenboer.eu/";
      description = "AI agent runtime";
      icon = "mdi-robot";
      siteMonitor = "http://127.0.0.1:42617/";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "zeroclaw";
        serviceName = "podman-zeroclaw";
        text = config.environment.etc."containers/systemd/zeroclaw.container".text;
      })
    ];
    systemd.units."podman-zeroclaw.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/zeroclaw.container".text = ''
      [Unit]
      Description=ZeroClaw agent runtime
      Wants=network-online.target
      BindsTo=zeroclaw-proxy-filter.service
      PartOf=zeroclaw-proxy-filter.service
      After=network-online.target zeroclaw-proxy-filter.service
      RequiresMountsFor=/nas/docker/zeroclaw/config /nas/docker/zeroclaw/data

      [Container]
      Image=ghcr.io/zeroclaw-labs/zeroclaw:v0.8.6
      ContainerName=zeroclaw
      ServiceName=podman-zeroclaw
      # Match the existing NAS owner; ZeroClaw checks the runtime directory UID.
      User=1024
      Group=100
      DropCapability=all
      NoNewPrivileges=true
      PublishPort=0.0.0.0:42617:42617
      Volume=/nas/docker/zeroclaw/data:/zeroclaw-data
      Volume=/nas/docker/zeroclaw/config:/zeroclaw-data/.zeroclaw
      Volume=/nas/docker/zeroclaw/data/agents:/zeroclaw-data/.zeroclaw/agents
      Environment=ZEROCLAW_gateway__host=0.0.0.0
      Environment=ZEROCLAW_gateway__allow_public_bind=true
      Environment=ZEROCLAW_gateway__require_pairing=true
      Environment=ZEROCLAW_gateway__allow_remote_admin=true

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      UMask=0077
      # NFS owns permission mapping; do not chown/chmod existing NAS directories.
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p /nas/docker/zeroclaw/config /nas/docker/zeroclaw/data /nas/docker/zeroclaw/data/agents

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
