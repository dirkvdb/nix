{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.quadlets.lgtv2mqtt.enable = lib.mkEnableOption "the LG TV MQTT bridge Podman Quadlet";

  config = lib.mkIf config.quadlets.lgtv2mqtt.enable {
    virtualisation.podman.enable = true;

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "lgtv2mqtt";
        serviceName = "podman-lgtv2mqtt";
        text = config.environment.etc."containers/systemd/lgtv2mqtt.container".text;
      })
    ];
    systemd.units."podman-lgtv2mqtt.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      mqtt_user = { };
      mqtt_pass = { };
      "mqtt/cert".restartUnits = [ "podman-lgtv2mqtt.service" ];
    };
    sops.templates."lgtv2mqtt-env" = {
      mode = "0400";
      restartUnits = [ "podman-lgtv2mqtt.service" ];
      content = ''
        LGTV2MQTT_MQTT_URL=mqtts://${config.sops.placeholder.mqtt_user}:${config.sops.placeholder.mqtt_pass}@mqtt.lan:8883
      '';
    };

    environment.etc."containers/systemd/lgtv2mqtt.container".text = ''
      [Unit]
      Description=LG TV to MQTT bridge
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}
      RequiresMountsFor=/opt/stacks/lgtv2mqtt/data

      [Container]
      Image=ghcr.io/hobbyquaker/lgtv2mqtt:latest
      AutoUpdate=registry
      ContainerName=lgtv2mqtt
      ServiceName=podman-lgtv2mqtt
      User=1026
      Group=100
      Network=bridge
      Volume=/opt/stacks/lgtv2mqtt/data:/data
      Volume=/run/lgtv2mqtt/mqtt.crt:/certs/mqtt.crt:ro
      EnvironmentFile=${config.sops.templates."lgtv2mqtt-env".path}
      Environment=LGTV2MQTT_TV=192.168.1.18
      Environment=LGTV2MQTT_VERIFY_CERT=tofu
      Environment=LGTV2MQTT_MQTT_TLS_CA=/certs/mqtt.crt

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      RuntimeDirectory=lgtv2mqtt
      RuntimeDirectoryMode=0700
      UMask=0077
      ExecStartPre=${pkgs.coreutils}/bin/install -d -m 0750 -o 1026 -g 100 /opt/stacks/lgtv2mqtt/data
      # Allow the container user to read the CA without changing the shared secret's permissions.
      ExecStartPre=${pkgs.coreutils}/bin/install -m 0444 ${
        config.sops.secrets."mqtt/cert".path
      } /run/lgtv2mqtt/mqtt.crt

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
