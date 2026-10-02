{
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
                href = "http://mediastation:8082";
                description = "Dashboard status";
                icon = "homepage";
                siteMonitor = "http://127.0.0.1:8082";
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

    networking.firewall.allowedTCPPorts = [ 8082 ];

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
