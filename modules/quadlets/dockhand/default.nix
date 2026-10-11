{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.dockhand.enable = lib.mkEnableOption "the Dockhand Podman Quadlet";

  config = lib.mkIf config.quadlets.dockhand.enable {
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
    };
    networking.firewall.allowedTCPPorts = [ 3000 ];

    services.homepage-dashboard.quadletEntries.Dockhand = {
      href = "http://${config.networking.hostName}:3000";
      description = "Container and stack management";
      icon = "docker";
      siteMonitor = "http://127.0.0.1:3000";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "dockhand";
        serviceName = "podman-dockhand";
        text = config.environment.etc."containers/systemd/dockhand.container".text;
      })
    ];
    systemd.units."podman-dockhand.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/dockhand.container".text = ''
      [Unit]
      Description=Dockhand container management
      Wants=network-online.target
      After=network-online.target podman.socket
      Requires=podman.socket
      RequiresMountsFor=/var/lib/dockhand

      [Container]
      Image=docker.io/fnsys/dockhand:v1.0.53
      AutoUpdate=registry
      ContainerName=dockhand
      ServiceName=podman-dockhand
      User=0:0
      PublishPort=3000:3000
      Volume=/run/podman/podman.sock:/var/run/docker.sock
      Volume=/var/lib/dockhand:/var/lib/dockhand
      Environment=DATA_DIR=/var/lib/dockhand

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      StateDirectory=dockhand
      StateDirectoryMode=0700

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
