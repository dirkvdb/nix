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
    networking.firewall.allowedTCPPorts = [
      8086
      8087
    ];

    services.homepage-dashboard.quadletEntries.FreshRSS = {
      href = "http://${config.services.homepage-dashboard.publicHostName}:8086/";
      description = "RSS feed reader backend and administration";
      icon = "freshrss";
      siteMonitor = "http://127.0.0.1:8086/";
    };

    services.homepage-dashboard.quadletEntries."Fresher RSS" = {
      href = "http://${config.services.homepage-dashboard.publicHostName}:8087/reader/";
      description = "Modern frontend for FreshRSS";
      icon = "freshrss";
      siteMonitor = "http://127.0.0.1:8087/reader/";
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

    sops.secrets.freshrss_refresh_tokens = { };
    sops.templates."freshrss-env" = {
      mode = "0400";
      restartUnits = [ "podman-freshrss.service" ];
      content = ''
        FRESHRSS_REFRESH_TOKENS=${config.sops.placeholder.freshrss_refresh_tokens}
        FRESHRSS_API_PASSWORDS=${config.sops.placeholder.freshrss_refresh_tokens}
      '';
    };

    environment.etc."containers/systemd/freshrss.container".text = ''
      [Unit]
      Description=FreshRSS feed reader with Fresher RSS frontend
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}
      RequiresMountsFor=/nas/docker/freshrss/data /nas/docker/freshrss/extensions

      [Container]
      Image=docker.io/dirkvdb/fresher-rss:latest
      Pull=always
      ContainerName=freshrss
      ServiceName=podman-freshrss
      PublishPort=8086:80
      PublishPort=8087:80
      Environment=TZ=Europe/Brussels
      Environment=CRON_MIN=*/15
      Environment=FRESHRSS_URL=http://127.0.0.1
      Environment=FRESHER_API_URL=/api/greader.php
      Environment=IMAGE_UNREAD_CACHE_ENABLED=true
      Environment=CONTENT_UNREAD_CACHE_ENABLED=true
      EnvironmentFile=${config.sops.templates."freshrss-env".path}
      Volume=/nas/docker/freshrss/data:/var/www/FreshRSS/data
      Volume=/nas/docker/freshrss/extensions:/var/www/FreshRSS/extensions

      HealthCmd=none

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
