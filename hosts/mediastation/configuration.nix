{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix

    inputs.stylix.nixosModules.stylix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  config = {
    system.stateVersion = "26.05";

    stylix.enable = true;
    local.headless = true;

    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
      ];
    };

    networking.hosts."192.168.1.13" = [ "nas.local" ];

    environment.systemPackages = [ pkgs.ghostty.terminfo ];

    virtualisation.podman.enable = true;

    services.cockpit = {
      enable = true;
      openFirewall = true;
      plugins = [ pkgs.cockpit-podman ];
      allowed-origins = [ "*" ];
      settings.WebService.AllowUnencrypted = true;
    };

    systemd.services.cockpit.serviceConfig = {
      ExecStartPre = [ "" ];
      ExecStart = [
        ""
        "${pkgs.cockpit}/libexec/cockpit-tls --no-tls"
      ];
    };

    services.homepage-dashboard = {
      enable = true;
      listenPort = 8084;
      openFirewall = true;
      allowedHosts = "*";
      settings = {
        title = "Mediastation";
        description = "Service dashboard";
      };
      services = [
        {
          Administration = [
            {
              Cockpit = {
                href = "http://mediastation:9090";
                description = "Host, services, logs and Podman";
                icon = "cockpit";
              };
            }
            {
              Homepage = {
                href = "http://mediastation:8084";
                description = "Dashboard status";
                icon = "homepage";
                siteMonitor = "http://127.0.0.1:8084";
              };
            }
            {
              Frigate = {
                href = "http://mediastation:8085/";
                description = "Camera recordings and live view";
                icon = "frigate";
                siteMonitor = "http://127.0.0.1:8085/";
              };
            }

          ];
        }
        {
          Storage = [
            {
              Synology = {
                href = "https://nas.local:5001";
                description = "Remote NFS storage";
                icon = "synology";
              };
            }
          ];
        }
        {
          "Arr" = [
            {
              Sonarr = {
                href = "http://sonarr.arr";
                description = "TV series management";
                icon = "sonarr";
                siteMonitor = "http://sonarr.arr";
              };
            }
            {
              Radarr = {
                href = "http://radarr.arr";
                description = "Movie management";
                icon = "radarr";
                siteMonitor = "http://radarr.arr";
              };
            }
            {
              Lidarr = {
                href = "http://lidarr.arr";
                description = "Music management";
                icon = "lidarr";
                siteMonitor = "http://lidarr.arr";
              };
            }
            {
              Prowlarr = {
                href = "http://prowlarr.arr";
                description = "Indexer management";
                icon = "prowlarr";
                siteMonitor = "http://prowlarr.arr";
              };
            }
            {
              Bazarr = {
                href = "http://bazarr.arr";
                description = "Subtitle management";
                icon = "bazarr";
                siteMonitor = "http://bazarr.arr";
              };
            }
            {
              Seerr = {
                href = "http://seerr.arr";
                description = "Media requests";
                icon = "seerr";
                siteMonitor = "http://seerr.arr";
              };
            }
            {
              Jellyfin = {
                href = "http://jellyfin.arr";
                description = "Media streaming";
                icon = "jellyfin";
                siteMonitor = "http://jellyfin.arr";
              };
            }

          ];
        }
      ];
      widgets = [
        {
          resources = {
            label = "Host";
            disk = "/";
            uptime = true;
          };
        }
      ];
    };
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

    services.frigate = {
      enable = true;
      hostname = "mediastation";
      settings = {
        mqtt = {
          enabled = true;
          host = "mqtt.lan";
          user = "{FRIGATE_MQTT_USER}";
          password = "{FRIGATE_MQTT_PASSWORD}";
        };
        tls.enabled = false;
        go2rtc.streams = {
          birdcam = [ "{FRIGATE_BIRDCAM_MAIN_URL}" ];
          birdcam_sub = [ "{FRIGATE_BIRDCAM_SUB_URL}" ];
        };
        cameras.birdcam = {
          enabled = true;
          ffmpeg.inputs = [
            {
              path = "{FRIGATE_BIRDCAM_MAIN_URL}";
              roles = [
                "audio"
                "record"
              ];
            }
            {
              path = "{FRIGATE_BIRDCAM_SUB_URL}";
              roles = [ "detect" ];
            }
          ];
          detect.enabled = false;
          live.streams = {
            main_stream = "birdcam";
            sub_stream = "birdcam_sub";
          };
          motion = {
            threshold = 50;
            contour_area = 20;
            improve_contrast = true;
            mask = "0.629,0.154,0.653,0.714,0.975,0.626,0.942,0.014";
          };
          notifications.enabled = true;
          zones.Nest = {
            coordinates = "0.145,0.305,0.259,0.982,0.561,0.868,0.431,0.163";
            loitering_time = 0;
            inertia = 3;
          };
          review.alerts.required_zones = [ "Nest" ];
        };
        detect.enabled = true;
        record = {
          enabled = true;
          alerts.retain.days = 30;
          detections.retain.days = 30;
          continuous.days = 0;
          motion.days = 7;
        };
        version = "0.17-0";
        notifications = {
          enabled = true;
          email = "{FRIGATE_NOTIFICATION_EMAIL}";
        };
      };
      preCheckConfig = ''
        export FRIGATE_MQTT_USER=build-check FRIGATE_MQTT_PASSWORD=build-check
        export FRIGATE_NOTIFICATION_EMAIL=frigate@example.invalid
        export FRIGATE_BIRDCAM_MAIN_URL=rtsp://example.invalid/live/0/MAIN
        export FRIGATE_BIRDCAM_SUB_URL=rtsp://example.invalid/live/0/SUB
      '';
    };

    sops.secrets.mqtt_user = { };
    sops.secrets.frigate_email = { };
    sops.secrets.frigate_birdcam_main_url = { };
    sops.secrets.frigate_birdcam_sub_url = { };
    sops.templates."frigate-env".content = ''
      FRIGATE_MQTT_USER="${config.sops.placeholder.mqtt_user}"
      FRIGATE_MQTT_PASSWORD="${config.sops.placeholder.mqtt_pass}"
      FRIGATE_NOTIFICATION_EMAIL="${config.sops.placeholder.frigate_email}"
      FRIGATE_BIRDCAM_MAIN_URL="${config.sops.placeholder.frigate_birdcam_main_url}"
      FRIGATE_BIRDCAM_SUB_URL="${config.sops.placeholder.frigate_birdcam_sub_url}"
    '';
    sops.templates."go2rtc-config".content = ''
      api:
        listen: 127.0.0.1:1984
      streams:
        birdcam:
          - "${config.sops.placeholder.frigate_birdcam_main_url}"
        birdcam_sub:
          - "${config.sops.placeholder.frigate_birdcam_sub_url}"
    '';

    services.go2rtc.enable = true;
    systemd.services.go2rtc.serviceConfig = {
      LoadCredential = [ "go2rtc.yaml:${config.sops.templates."go2rtc-config".path}" ];
      ExecStart = lib.mkForce "${config.services.go2rtc.package}/bin/go2rtc -config %d/go2rtc.yaml";
    };
    sops.secrets.hl_service_pass = { };
    systemd.services.frigate.serviceConfig = {
      EnvironmentFile = config.sops.templates."frigate-env".path;
      LoadCredential = [ "admin-password:${config.sops.secrets.hl_service_pass.path}" ];
      ExecStartPost = [
        (
          "+"
          + (pkgs.writeShellScript "frigate-sync-admin-password" ''
            set -eu
            exec ${config.services.frigate.package.python.interpreter} - <<'PY'
            import os
            import sqlite3
            import sys
            import time
            from pathlib import Path

            from frigate.api.auth import hash_password, verify_password

            password = Path(os.environ["CREDENTIALS_DIRECTORY"], "admin-password").read_text().rstrip("\n")
            database = "/var/lib/frigate/frigate.db"

            for _ in range(120):
                try:
                    connection = sqlite3.connect(database, timeout=2)
                    row = connection.execute(
                        "SELECT password_hash FROM user WHERE username = ?", ("admin",)
                    ).fetchone()
                    if row is not None:
                        if not verify_password(password, row[0]):
                            connection.execute(
                                "UPDATE user SET password_hash = ?, password_changed_at = CURRENT_TIMESTAMP WHERE username = ?",
                                (hash_password(password), "admin"),
                            )
                            connection.commit()
                        connection.close()
                        print("Frigate admin password synchronized from SOPS")
                        break
                    connection.close()
                except sqlite3.Error:
                    pass
                time.sleep(1)
            else:
                sys.exit("Timed out waiting for Frigate admin account database")
            PY
          '')
        )
      ];
    };

    services.nginx.virtualHosts."mediastation".listen = [
      {
        addr = "0.0.0.0";
        port = 8085;
      }
    ];

    networking.firewall.allowedTCPPorts = [ 8085 ];

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;

        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      system = {
        cpu.cores = 4;

        nix = {
          ld.enable = true;
        };

        boot.systemd.enable = true;
        network = {
          enable = true;
          hostname = "mediastation";
          wakeOnLan = true;
          interface = "enp2s0";
          networkmanager = {
            enable = true;
          };
        };

        nfs-mounts = {
          enable = true;
          presets.nas = true;
        };

        utils = {
          sysadmin = true;
        };
      };

      apps = {
        sops.enable = true;
        herdr.enable = true;
      };

      services = {
        ssh = {
          enable = true;
          disablePasswordAuth = true;
        };
        fwupd.enable = true;
        nixflix.enable = true;
        # nordvpn.enable = true;
      };
    };
  };
}
