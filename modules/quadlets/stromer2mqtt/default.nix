{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.quadlets.stromer2mqtt.enable = lib.mkEnableOption "the Stromer MQTT bridge Podman Quadlet";

  config = lib.mkIf config.quadlets.stromer2mqtt.enable {
    virtualisation.podman.enable = true;

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "stromer2mqtt";
        serviceName = "podman-stromer2mqtt";
        text = config.environment.etc."containers/systemd/stromer2mqtt.container".text;
      })
    ];
    systemd.units."podman-stromer2mqtt.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      "stromer/username" = { };
      "stromer/password" = { };
      "stromer/client_id" = { };
      mqtt_user = { };
      mqtt_pass = { };
      "mqtt/cert".restartUnits = [ "podman-stromer2mqtt.service" ];
    };
    sops.templates."stromer2mqtt-env" = {
      mode = "0400";
      restartUnits = [ "podman-stromer2mqtt.service" ];
      content = ''
        S2M_STROMER_USERNAME=${config.sops.placeholder."stromer/username"}
        S2M_STROMER_PASSWORD=${config.sops.placeholder."stromer/password"}
        S2M_STROMER_CLIENT_ID=${config.sops.placeholder."stromer/client_id"}
        S2M_MQTT_USER=${config.sops.placeholder.mqtt_user}
        S2M_MQTT_PASS=${config.sops.placeholder.mqtt_pass}
      '';
    };

    environment.etc."containers/systemd/stromer2mqtt.container".text = ''
      [Unit]
      Description=Stromer to MQTT bridge
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}

      [Container]
      Image=docker.io/dirkvdb/stromer2mqtt:main
      AutoUpdate=registry
      ContainerName=stromer2mqtt
      ServiceName=podman-stromer2mqtt
      Volume=/run/stromer2mqtt/mqtt.crt:/certs/mqtt.crt:ro
      EnvironmentFile=${config.sops.templates."stromer2mqtt-env".path}
      Environment=RUST_LOG=stromer2mqtt=debug
      Environment=S2M_MQTT_ADDRESS=mqtt.lan
      Environment=S2M_MQTT_PORT=8883
      Environment=S2M_MQTT_CA_CERT=/certs/mqtt.crt
      Environment=S2M_MQTT_BASE_TOPIC=home/stromer
      Environment=S2M_HASS_DISCOVERY=true
      StopTimeout=30

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=60
      RuntimeDirectory=stromer2mqtt
      RuntimeDirectoryMode=0700
      UMask=0077
      # Allow the non-root image user to read the CA without changing the shared secret's permissions.
      ExecStartPre=${pkgs.coreutils}/bin/install -m 0444 ${
        config.sops.secrets."mqtt/cert".path
      } /run/stromer2mqtt/mqtt.crt

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
