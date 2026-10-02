{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.quadlets.frigate;
  settingsFile = pkgs.writeText "frigate-settings.json" (builtins.toJSON (import ./settings.nix));
  syncAdmin = pkgs.writeShellScript "frigate-sync-admin-password" ''
    set -eu
    exec ${pkgs.coreutils}/bin/timeout 150s \
      ${config.virtualisation.podman.package}/bin/podman exec --interactive \
      --env PYTHONPATH=/opt/frigate --workdir /opt/frigate \
      frigate /usr/bin/python3 /usr/local/bin/frigate-sync-admin.py \
      < "$CREDENTIALS_DIRECTORY/admin-password"
  '';
in
{
  imports = [ ../homepage.nix ];

  options.quadlets.frigate.enable = lib.mkEnableOption "the Frigate Podman Quadlet";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.frigate.enable;
        message = "Disable native services.frigate before enabling quadlets.frigate (shared database).";
      }
      {
        assertion = !config.services.go2rtc.enable;
        message = "quadlets.frigate uses bundled go2rtc; disable the standalone services.go2rtc.";
      }
    ];

    virtualisation.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 8085 ];

    services.homepage-dashboard.quadletEntries.Frigate = {
      href = "http://${config.networking.hostName}:8085/";
      description = "Camera recordings and live view";
      icon = "frigate";
      siteMonitor = "http://127.0.0.1:8085/";
    };

    # Activation needs a store-backed unit for secret restarts and lifecycle management.
    systemd.packages = [
      (import ../generate-units.nix {
        inherit pkgs;
        podman = config.virtualisation.podman.package;
        name = "frigate";
        text = config.environment.etc."containers/systemd/frigate.container".text;
      })
    ];
    systemd.units."frigate.service".wantedBy = [ "multi-user.target" ];

    sops.secrets = {
      mqtt_user = { };
      mqtt_pass = { };
      frigate_birdcam_main_url = { };
      frigate_birdcam_sub_url = { };
      frigate_email.restartUnits = [ "frigate.service" ];
      hl_service_pass.restartUnits = [ "frigate.service" ];
    };
    sops.templates."frigate-env" = {
      mode = "0400";
      restartUnits = [ "frigate.service" ];
      # Podman env files are literal KEY=value, not shell/systemd quoted values.
      content = ''
        FRIGATE_MQTT_USER=${config.sops.placeholder.mqtt_user}
        FRIGATE_MQTT_PASSWORD=${config.sops.placeholder.mqtt_pass}
        FRIGATE_NOTIFICATION_EMAIL=${config.sops.placeholder.frigate_email}
        FRIGATE_BIRDCAM_MAIN_URL=${config.sops.placeholder.frigate_birdcam_main_url}
        FRIGATE_BIRDCAM_SUB_URL=${config.sops.placeholder.frigate_birdcam_sub_url}
      '';
    };

    environment.etc."containers/systemd/frigate.container".text = ''
      [Unit]
      Description=Frigate NVR
      After=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      Requires=${lib.optionalString config.sops.useSystemdActivation "sops-install-secrets.service "}network-online.target
      RequiresMountsFor=/var/lib/frigate

      [Container]
      # Matches the pinned native nixpkgs package; upstream's stable 0.17.2 release.
      Image=ghcr.io/blakeblackshear/frigate:0.17.2
      ContainerName=frigate
      PublishPort=8085:8971
      EnvironmentFile=${config.sops.templates."frigate-env".path}
      Environment=TZ=${if config.time.timeZone == null then "UTC" else config.time.timeZone}
      Environment=CONFIG_FILE=/run/frigate-quadlet/config.yml
      Volume=/var/lib/frigate:/config
      Volume=/var/lib/frigate:/media/frigate
      # Keep absolute native recording/export paths in the existing DB usable.
      Volume=/var/lib/frigate:/var/lib/frigate
      Volume=/run/frigate-quadlet:/run/frigate-quadlet
      Volume=${./sync-admin.py}:/usr/local/bin/frigate-sync-admin.py:ro
      ShmSize=256m
      Tmpfs=/tmp/cache:rw,size=1000000000
      StopTimeout=60

      [Service]
      Restart=always
      RestartSec=5
      TimeoutStartSec=900
      TimeoutStopSec=90
      RuntimeDirectory=frigate-quadlet
      RuntimeDirectoryMode=0700
      UMask=0077
      LoadCredential=notification-email:${config.sops.secrets.frigate_email.path}
      LoadCredential=admin-password:${config.sops.secrets.hl_service_pass.path}
      ExecStartPre=${pkgs.python3}/bin/python3 ${./render-config.py} ${settingsFile} %d/notification-email /run/frigate-quadlet/config.yml
      ExecStartPost=${syncAdmin}

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
