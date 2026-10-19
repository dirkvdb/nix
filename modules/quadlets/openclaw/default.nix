{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsFile = pkgs.writeText "openclaw.json" (builtins.toJSON (import ./settings.nix));
  # Filter host-published traffic before Podman's DNAT bypasses the host INPUT chain.
  proxyIngressRule = "! -i lo -m addrtype --dst-type LOCAL -p tcp --dport 18789 -m iprange ! --src-range 192.168.1.13-192.168.1.14 -j DROP";
in
{
  imports = [ ../homepage.nix ];

  options.quadlets.openclaw.enable = lib.mkEnableOption "the OpenClaw gateway Podman Quadlet";

  config = lib.mkIf config.quadlets.openclaw.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 18789 ];

    systemd.services.openclaw-proxy-filter = {
      description = "Restrict OpenClaw ingress to its reverse proxy";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "openclaw-proxy-filter-start" ''
          set -eu
          ${pkgs.iptables}/bin/iptables -w -t mangle -C PREROUTING ${proxyIngressRule} 2>/dev/null || \
            ${pkgs.iptables}/bin/iptables -w -t mangle -A PREROUTING ${proxyIngressRule}
        '';
        ExecStop = pkgs.writeShellScript "openclaw-proxy-filter-stop" ''
          ${pkgs.iptables}/bin/iptables -w -t mangle -D PREROUTING ${proxyIngressRule} || true
        '';
      };
    };

    services.homepage-dashboard.quadletEntries.OpenClaw = {
      href = "https://claw.hl.vandenboer.eu/";
      description = "AI agent gateway";
      icon = "mdi-robot";
      siteMonitor = "http://127.0.0.1:18789/healthz";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "openclaw";
        serviceName = "podman-openclaw";
        text = config.environment.etc."containers/systemd/openclaw.container".text;
      })
    ];
    systemd.units."podman-openclaw.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/openclaw.container".text = ''
      [Unit]
      Description=OpenClaw agent gateway
      Wants=network-online.target
      BindsTo=openclaw-proxy-filter.service
      PartOf=openclaw-proxy-filter.service
      After=network-online.target openclaw-proxy-filter.service
      RequiresMountsFor=/var/lib/openclaw /nas/docker/openclaw/config /nas/docker/openclaw/data

      [Container]
      Image=ghcr.io/openclaw/openclaw:latest
      Pull=always
      ContainerName=openclaw
      ServiceName=podman-openclaw
      User=1024:100
      DropCapability=all
      NoNewPrivileges=true
      PublishPort=0.0.0.0:18789:18789
      PublishPort=127.0.0.1:18790:18790
      Volume=/nas/docker/openclaw/config:/home/node/.openclaw
      Volume=/nas/docker/openclaw/data:/home/node/.openclaw/workspace
      Volume=${settingsFile}:/home/node/.openclaw/openclaw.json:ro
      Mount=type=tmpfs,destination=/tmp/openclaw,tmpfs-mode=0700,U=true
      EnvironmentFile=/var/lib/openclaw/env
      Environment=HOME=/home/node
      Environment=TMPDIR=/tmp/openclaw
      Environment=XDG_CACHE_HOME=/tmp/openclaw
      Environment=NPM_CONFIG_CACHE=/home/node/.openclaw/.npm
      Environment=OPENCLAW_NO_RESPAWN=1
      Environment=OPENCLAW_CONFIG_READONLY=1
      Environment=OPENCLAW_STATE_DIR=/home/node/.openclaw
      Exec=node openclaw.mjs gateway --bind lan --port 18789
      StopTimeout=60

      [Service]
      Restart=on-failure
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      StateDirectory=openclaw
      StateDirectoryMode=0700
      UMask=0077
      ExecStartPre=${pkgs.writeShellScript "openclaw-prepare" ''
        set -eu

        if [ ! -s /var/lib/openclaw/env ]; then
          umask 077
          token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
          printf 'OPENCLAW_GATEWAY_TOKEN=%s\n' "$token" > /var/lib/openclaw/env.tmp
          ${pkgs.coreutils}/bin/mv /var/lib/openclaw/env.tmp /var/lib/openclaw/env
        fi
      ''}

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
