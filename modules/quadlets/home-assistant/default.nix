{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.home-assistant.enable = lib.mkEnableOption "the Home Assistant Podman Quadlet";

  config = lib.mkIf config.quadlets.home-assistant.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 8123 ];

    services.homepage-dashboard.quadletEntries."Home Assistant" = {
      href = "http://${config.networking.hostName}:8123";
      description = "Home automation";
      icon = "home-assistant";
      siteMonitor = "http://127.0.0.1:8123";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "home-assistant";
        serviceName = "podman-home-assistant";
        text = config.environment.etc."containers/systemd/home-assistant.container".text;
      })
    ];
    systemd.units."podman-home-assistant.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/home-assistant.container".text = ''
      [Unit]
      Description=Home Assistant
      Wants=network-online.target
      After=network-online.target

      [Container]
      Image=ghcr.io/home-assistant/home-assistant:2026.9.4
      ContainerName=home-assistant
      ServiceName=podman-home-assistant
      Network=host
      Volume=/var/lib/home-assistant:/config
      Volume=/run/dbus:/run/dbus:ro
      Environment=TZ=${if config.time.timeZone == null then "UTC" else config.time.timeZone}
      PodmanArgs=--privileged
      StopTimeout=60

      [Service]
      Restart=always
      TimeoutStartSec=900
      TimeoutStopSec=90
      StateDirectory=home-assistant
      StateDirectoryMode=0700

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
