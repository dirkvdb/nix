{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsFile = pkgs.writeText "openclaw-defaults.json" (builtins.toJSON (import ./settings.nix));
  startup = pkgs.writeText "openclaw-start.mjs" (builtins.readFile ./start.mjs);
  runtimeClosure = pkgs.closureInfo {
    rootPaths = [
      pkgs.signal-cli
      pkgs.gh
    ];
  };
  # Filter host-published traffic before Podman's DNAT bypasses the host INPUT chain.
  proxyIngressRule = "! -i lo -m addrtype --dst-type LOCAL -p tcp --dport 18789 -m iprange ! --src-range 192.168.1.13-192.168.1.14 -j DROP";
in
{
  imports = [ ../homepage.nix ];

  options.quadlets.openclaw.enable = lib.mkEnableOption "the OpenClaw gateway Podman Quadlet";

  config = lib.mkIf config.quadlets.openclaw.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 18789 ];

    systemd.tmpfiles.rules = [
      "d /var/lib/openclaw 0700 root root -"
      "d /var/lib/openclaw/config 0700 1024 100 -"
      "d /var/lib/openclaw/data 0700 1024 100 -"
    ];

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
        source = config.environment.etc."containers/systemd/openclaw.container".source;
      })
    ];
    systemd.units."podman-openclaw.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/openclaw.container".source =
      let
        template = pkgs.writeText "openclaw.container.in" ''
          [Unit]
          Description=OpenClaw agent gateway
          Wants=network-online.target
          BindsTo=openclaw-proxy-filter.service
          PartOf=openclaw-proxy-filter.service
          After=network-online.target openclaw-proxy-filter.service
          RequiresMountsFor=/var/lib/openclaw/config /var/lib/openclaw/data

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
          Volume=/var/lib/openclaw/config:/home/node/.openclaw
          Volume=/var/lib/openclaw/data:/home/node/.openclaw/workspace
          Volume=${settingsFile}:/etc/openclaw/defaults.json:ro
          Volume=${startup}:/etc/openclaw/start.mjs:ro
          Volume=${pkgs.signal-cli}/bin/signal-cli:/usr/local/bin/signal-cli:ro
          Volume=${pkgs.gh}/bin/gh:/usr/local/bin/gh:ro
          @runtimeMounts@
          Mount=type=tmpfs,destination=/tmp/openclaw,tmpfs-mode=0700,U=true
          EnvironmentFile=/var/lib/openclaw/env
          Environment=HOME=/home/node
          Environment=TMPDIR=/tmp/openclaw
          Environment=XDG_CACHE_HOME=/tmp/openclaw
          Environment=XDG_DATA_HOME=/home/node/.openclaw
          Environment=NPM_CONFIG_CACHE=/home/node/.openclaw/.npm
          Environment=GH_CONFIG_DIR=/home/node/.openclaw/gh
          Environment=OPENCLAW_NO_RESPAWN=1
          Environment=OPENCLAW_STATE_DIR=/home/node/.openclaw
          Exec=node /etc/openclaw/start.mjs
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
      in
      pkgs.runCommand "openclaw.container" { } ''
        runtimeMounts="$(while IFS= read -r storePath; do
          printf 'Volume=%s:%s:ro\n' "$storePath" "$storePath"
        done < ${runtimeClosure}/store-paths)"
        substitute ${template} "$out" --replace-fail '@runtimeMounts@' "$runtimeMounts"
      '';
  };
}
