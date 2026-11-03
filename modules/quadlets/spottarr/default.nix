{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.spottarr.enable = lib.mkEnableOption "the Spottarr Podman Quadlet";

  config = lib.mkIf config.quadlets.spottarr.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 8383 ];

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "spottarr";
        serviceName = "podman-spottarr";
        text = config.environment.etc."containers/systemd/spottarr.container".text;
      })
    ];
    systemd.units."podman-spottarr.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      "usenet/eweka/username" = { };
      "usenet/eweka/password" = { };
    };
    sops.templates."spottarr-env" = {
      mode = "0400";
      restartUnits = [ "podman-spottarr.service" ];
      content = ''
        USENET__HOSTNAME=news.eweka.nl
        USENET__USERNAME=${config.sops.placeholder."usenet/eweka/username"}
        USENET__PASSWORD=${config.sops.placeholder."usenet/eweka/password"}
      '';
    };

    environment.etc."containers/systemd/spottarr.container".text = ''
      [Unit]
      Description=Spottarr Usenet and Spotnet indexer
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}
      RequiresMountsFor=/nas/data

      [Container]
      Image=ghcr.io/spottarr/spottarr:latest
      AutoUpdate=registry
      ContainerName=spottarr
      ServiceName=podman-spottarr
      User=1026:100
      PublishPort=8383:8383
      EnvironmentFile=${config.sops.templates."spottarr-env".path}
      Environment=USENET__PORT=563
      Environment=USENET__USETLS=true
      Environment=USENET__MAXCONNECTIONS=10
      Environment=SPOTNET__RETRIEVEAFTER=2023-01-01T00:00:00Z
      Environment=SPOTNET__IMPORTBATCHSIZE=10000
      Environment=SPOTNET__RETENTIONDAYS=3650
      Environment=SPOTNET__IMPORTADULTCONTENT=false
      Environment=TZ=Europe/Brussels
      Volume=/nas/data/sporarr:/data
      PodmanArgs=--memory=200m

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      ExecStartPre=${pkgs.util-linux}/bin/setpriv --reuid=1026 --regid=100 --clear-groups ${pkgs.coreutils}/bin/mkdir -p -m 0700 /nas/data/sporarr
      ExecStartPre=${pkgs.util-linux}/bin/setpriv --reuid=1026 --regid=100 --clear-groups ${pkgs.coreutils}/bin/test -w /nas/data/sporarr

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
