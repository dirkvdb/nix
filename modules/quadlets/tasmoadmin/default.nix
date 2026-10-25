{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.tasmoadmin.enable = lib.mkEnableOption "the TasmoAdmin Podman Quadlet";

  config = lib.mkIf config.quadlets.tasmoadmin.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 9999 ];

    services.homepage-dashboard.quadletEntries.TasmoAdmin = {
      href = "http://${config.services.homepage-dashboard.publicHostName}:9999/";
      description = "Tasmota device management";
      icon = "tasmoadmin";
      siteMonitor = "http://127.0.0.1:9999/";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "tasmoadmin";
        serviceName = "podman-tasmoadmin";
        text = config.environment.etc."containers/systemd/tasmoadmin.container".text;
      })
    ];
    systemd.units."podman-tasmoadmin.service".wantedBy = [ "multi-user.target" ];

    systemd.timers.tasmoadmin-healthcheck = {
      wantedBy = [ "podman-tasmoadmin.service" ];
      bindsTo = [ "podman-tasmoadmin.service" ];
      after = [ "podman-tasmoadmin.service" ];
      partOf = [ "podman-tasmoadmin.service" ];
      timerConfig = {
        OnActiveSec = "30s";
        OnUnitActiveSec = "30s";
        AccuracySec = "1s";
      };
    };

    systemd.services.tasmoadmin-healthcheck = {
      description = "Check TasmoAdmin container health";
      after = [ "podman-tasmoadmin.service" ];
      requisite = [ "podman-tasmoadmin.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.virtualisation.podman.package}/bin/podman healthcheck run tasmoadmin";
        # Podman records failed probes in container health; only execution errors fail this unit.
        SuccessExitStatus = [ 1 ];
      };
    };

    environment.etc."containers/systemd/tasmoadmin.container".text = ''
      [Unit]
      Description=TasmoAdmin Tasmota device management
      RequiresMountsFor=/nas/docker/tasmoadmin/data

      [Container]
      Image=ghcr.io/tasmoadmin/tasmoadmin:latest
      AutoUpdate=registry
      ContainerName=tasmoadmin
      ServiceName=podman-tasmoadmin
      PublishPort=9999:80
      Volume=/nas/docker/tasmoadmin/data:/data
      WorkingDir=/tasmoadmin

      HealthCmd=curl -fsS http://127.0.0.1:80/ > /dev/null || exit 1
      HealthInterval=disable
      HealthTimeout=10s
      HealthRetries=3
      HealthStartPeriod=30s

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p /nas/docker/tasmoadmin/data

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
