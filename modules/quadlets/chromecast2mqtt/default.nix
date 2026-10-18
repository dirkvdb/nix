{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.quadlets.chromecast2mqtt.enable = lib.mkEnableOption "the Chromecast MQTT bridge Podman Quadlet";

  config = lib.mkIf config.quadlets.chromecast2mqtt.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedUDPPorts = [ 5353 ];

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "chromecast2mqtt";
        serviceName = "podman-chromecast2mqtt";
        text = config.environment.etc."containers/systemd/chromecast2mqtt.container".text;
      })
    ];
    systemd.units."podman-chromecast2mqtt.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      mqtt_user = { };
      mqtt_pass = { };
      "mqtt/cert".restartUnits = [ "podman-chromecast2mqtt.service" ];
    };
    sops.templates."chromecast2mqtt-env" = {
      mode = "0400";
      restartUnits = [ "podman-chromecast2mqtt.service" ];
      content = ''
        C2M_MQTT_USER=${config.sops.placeholder.mqtt_user}
        C2M_MQTT_PASS=${config.sops.placeholder.mqtt_pass}
      '';
    };

    environment.etc."containers/systemd/chromecast2mqtt.container".text = ''
      [Unit]
      Description=Chromecast to MQTT bridge
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}

      [Container]
      Image=docker.io/dirkvdb/chromecast2mqtt:latest
      AutoUpdate=registry
      ContainerName=chromecast2mqtt
      ServiceName=podman-chromecast2mqtt
      # mDNS discovery requires access to the host's multicast network.
      Network=host
      Volume=/run/chromecast2mqtt/mqtt-ca.crt:/run/secrets/mqtt-ca.crt:ro
      EnvironmentFile=${config.sops.templates."chromecast2mqtt-env".path}
      Environment=SECRETSPEC_PROVIDER=env
      Environment=C2M_MQTT_ADDRESS=mqtt.lan
      Environment=C2M_MQTT_PORT=8883
      Environment=C2M_MQTT_CA_CERT=/run/secrets/mqtt-ca.crt
      StopTimeout=60

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      RuntimeDirectory=chromecast2mqtt
      RuntimeDirectoryMode=0700
      UMask=0077
      # Allow the non-root image user to read the CA without changing the shared secret's permissions.
      ExecStartPre=${pkgs.coreutils}/bin/install -m 0444 ${
        config.sops.secrets."mqtt/cert".path
      } /run/chromecast2mqtt/mqtt-ca.crt

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
