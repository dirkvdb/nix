{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../homepage.nix ];

  options.quadlets.daikin2mqtt.enable = lib.mkEnableOption "the Daikin MQTT bridge Podman Quadlet";

  config = lib.mkIf config.quadlets.daikin2mqtt.enable {
    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 8076 ];

    services.homepage-dashboard.quadletEntries.Daikin = {
      href = "http://${config.networking.hostName}:8076/";
      description = "Daikin cloud to MQTT bridge";
      icon = "mdi-air-conditioner";
      siteMonitor = "http://127.0.0.1:8076/";
    };

    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "daikin2mqtt";
        serviceName = "podman-daikin2mqtt";
        text = config.environment.etc."containers/systemd/daikin2mqtt.container".text;
      })
    ];
    systemd.units."podman-daikin2mqtt.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      daikin_client_secret = { };
      daikin_oauth_callback = { };
      mqtt_user = { };
      mqtt_pass = { };
    };
    sops.templates."daikin2mqtt-env" = {
      mode = "0400";
      restartUnits = [ "podman-daikin2mqtt.service" ];
      content = ''
        DAIKIN_CLIENT_SECRET=${config.sops.placeholder.daikin_client_secret}
        DAIKIN_REDIRECT_URI=${config.sops.placeholder.daikin_oauth_callback}
        MQTT_USERNAME=${config.sops.placeholder.mqtt_user}
        MQTT_PASSWORD=${config.sops.placeholder.mqtt_pass}
      '';
    };

    environment.etc."containers/systemd/daikin2mqtt.container".text = ''
      [Unit]
      Description=Daikin cloud to MQTT bridge
      Wants=network-online.target
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      ${lib.optionalString config.sops.useSystemdActivation "Requires=sops-install-secrets.service"}
      RequiresMountsFor=/var/lib/daikin2mqtt

      [Container]
      Image=docker.io/dirkvdb/daikin2mqtt:latest
      ContainerName=daikin2mqtt
      ServiceName=podman-daikin2mqtt
      PublishPort=8076:8076
      Volume=/var/lib/daikin2mqtt/data:/data

      EnvironmentFile=${config.sops.templates."daikin2mqtt-env".path}
      Environment=SECRETSPEC_PROVIDER=env
      Environment=DAIKIN_CLIENT_ID=1m6p4D6Wzyu9VHBpo16EJd8i
      Environment=DAIKIN_DATA_DIR=/data
      Environment=DAIKIN_WEB_LISTEN=0.0.0.0:8076

      Environment=DAIKIN_MQTT_ADDRESS=mqtt.lan
      StopTimeout=60

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      StateDirectory=daikin2mqtt
      StateDirectoryMode=0700
      UMask=0077
      ExecStartPre=${pkgs.coreutils}/bin/install -d -m 0700 /var/lib/daikin2mqtt/data

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
