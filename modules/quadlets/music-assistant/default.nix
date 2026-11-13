{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.music-assistant.enable = lib.mkEnableOption "the Music Assistant Podman Quadlet";

  config = lib.mkIf config.quadlets.music-assistant.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [
      8095
      8097
    ];
    networking.firewall.allowedUDPPorts = [
      1900
      5353
    ];

    services.homepage-dashboard.quadletEntries."Music Assistant" = {
      href = "http://${config.services.homepage-dashboard.publicHostName}:8095";
      description = "Music library and multi-room audio";
      icon = "music-assistant";
      siteMonitor = "http://127.0.0.1:8095";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "music-assistant";
        serviceName = "podman-music-assistant";
        text = config.environment.etc."containers/systemd/music-assistant.container".text;
      })
    ];
    systemd.units."podman-music-assistant.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/music-assistant.container".text = ''
      [Unit]
      Description=Music Assistant server
      Wants=network-online.target
      After=network-online.target
      RequiresMountsFor=/nas/media/music

      [Container]
      Image=ghcr.io/music-assistant/server:latest
      AutoUpdate=registry
      ContainerName=music-assistant-server
      ServiceName=podman-music-assistant
      Network=host
      Volume=/var/lib/music-assistant:/data
      Volume=/nas/media/music:/media:ro
      Environment=LOG_LEVEL=info

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      StateDirectory=music-assistant
      StateDirectoryMode=0700

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
