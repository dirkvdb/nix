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

    virtualisation.podman.enable = true;

    services.cockpit = {
      enable = true;
      openFirewall = true;
      plugins = [ pkgs.cockpit-podman ];
    };

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      allowedHosts = "localhost:8082,127.0.0.1:8082,mediastation:8082,mediastation.local:8082";
      settings = {
        title = "Mediastation";
        description = "Service dashboard";
      };
      services = [
        {
          Administration = [
            {
              Cockpit = {
                href = "https://mediastation:9090";
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
          "Media *arr" = [
            {
              Sonarr = {
                href = "https://sonarr.arr";
                description = "TV series management";
                icon = "sonarr";
                siteMonitor = "https://sonarr.arr";
              };
            }
            {
              Radarr = {
                href = "https://radarr.arr";
                description = "Movie management";
                icon = "radarr";
                siteMonitor = "https://radarr.arr";
              };
            }
            {
              Lidarr = {
                href = "https://lidarr.arr";
                description = "Music management";
                icon = "lidarr";
                siteMonitor = "https://lidarr.arr";
              };
            }
            {
              Prowlarr = {
                href = "https://prowlarr.arr";
                description = "Indexer management";
                icon = "prowlarr";
                siteMonitor = "https://prowlarr.arr";
              };
            }
            {
              Bazarr = {
                href = "https://bazarr.arr";
                description = "Subtitle management";
                icon = "bazarr";
                siteMonitor = "https://bazarr.arr";
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
      };
    };
  };
}
