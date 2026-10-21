{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.freshrss.enable = lib.mkEnableOption "the FreshRSS Podman Quadlet";

  config = lib.mkIf config.quadlets.freshrss.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 8086 ];

    services.homepage-dashboard.quadletEntries.FreshRSS = {
      href = "http://${config.networking.hostName}:8086/";
      description = "RSS feed reader";
      icon = "freshrss";
      siteMonitor = "http://127.0.0.1:8086/";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "freshrss";
        serviceName = "podman-freshrss";
        text = config.environment.etc."containers/systemd/freshrss.container".text;
      })
    ];
    systemd.units."podman-freshrss.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/freshrss.container".text = ''
      [Unit]
      Description=FreshRSS feed reader
      Wants=network-online.target
      After=network-online.target
      RequiresMountsFor=/nas/docker/freshrss/data /nas/docker/freshrss/extensions

      [Container]
      Image=docker.io/freshrss/freshrss:latest
      ContainerName=freshrss
      ServiceName=podman-freshrss
      PublishPort=8086:80
      Environment=TZ=Europe/Brussels
      Environment=CRON_MIN=7,37
      Volume=/nas/docker/freshrss/data:/var/www/FreshRSS/data
      Volume=/nas/docker/freshrss/extensions:/var/www/FreshRSS/extensions

      HealthCmd=CMD cli/health.php
      HealthInterval=75s
      HealthTimeout=10s
      HealthStartPeriod=60s
      HealthRetries=3

      # Podman supports max-size, but not Docker's max-file option.
      LogDriver=k8s-file
      LogOpt=max-size=10m

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p /nas/docker/freshrss/data /nas/docker/freshrss/extensions

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
