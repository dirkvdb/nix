{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.homarr.enable = lib.mkEnableOption "the Homarr Podman Quadlet";

  config = lib.mkIf config.quadlets.homarr.enable {
    virtualisation.podman.enable = true;

    services.homepage-dashboard.quadletEntries.Homarr = {
      href = "http://${config.networking.hostName}:8083/";
      description = "Application dashboard";
      icon = "homarr";
      siteMonitor = "http://127.0.0.1:8083/";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "homarr";
        serviceName = "podman-homarr";
        text = config.environment.etc."containers/systemd/homarr.container".text;
      })
    ];
    systemd.units."podman-homarr.service".wantedBy = [ "multi-user.target" ];

    environment.etc."containers/systemd/homarr.container".text = ''
      [Unit]
      Description=Homarr dashboard

      [Container]
      Image=ghcr.io/homarr-labs/homarr:v1.77.2
      ContainerName=homarr
      ServiceName=podman-homarr
      PublishPort=8083:7575
      Volume=/var/lib/homarr/appdata:/appdata
      EnvironmentFile=/var/lib/homarr/env

      [Service]
      Restart=always
      TimeoutStartSec=900
      StateDirectory=homarr
      StateDirectoryMode=0700
      ExecStartPre=${pkgs.writeShellScript "homarr-prepare" ''
        set -eu
        ${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/homarr/appdata
        if [ ! -s /var/lib/homarr/env ]; then
          umask 077
          printf 'SECRET_ENCRYPTION_KEY=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" > /var/lib/homarr/env
        fi
      ''}

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
