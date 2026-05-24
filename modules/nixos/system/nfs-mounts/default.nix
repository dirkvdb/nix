{ lib, config, ... }:
let
  cfg = config.local.system.nfs-mounts;
in
{
  options.local.system.nfs-mounts = {
    enable = lib.mkEnableOption "NFS mounts";

    presets.nas = lib.mkEnableOption "standard NAS mounts (secrets, ssd, downloads, data, media, arr)";
    hosts = lib.mkOption {
      description = "Additional /etc/hosts entries, useful for pinning NFS server hostnames to IPv4 when IPv6 is also enabled";
      default = {
        "192.168.1.13" = [ "nas.local" ];
      };
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    };

    mounts = lib.mkOption {
      description = "NFS Mount configs";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrs;
          options = {
            device = lib.mkOption {
              type = lib.types.str;
              default = null;
              description = "NFS address and path";
            };

            fsType = lib.mkOption {
              type = lib.types.str;
              default = "nfs";
              description = "Filesystem type";
            };

            options = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                "rw"
                "defaults"
                "x-systemd.automount"
                "noauto"
                "_netdev" # filesystem requires a network connection before it can be mounted
                "x-systemd.idle-timeout=10min"
              ];
              description = "Default mount options";
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.presets.nas {
      local.system.nfs-mounts.mounts = {
        "/nas/secrets" = {
          device = lib.mkDefault "nas.local:/volume2/secrets";
        };
        "/nas/ssd" = {
          device = lib.mkDefault "nas.local:/volume2/ssd";
        };
        "/nas/downloads" = {
          device = lib.mkDefault "nas.local:/volume1/downloads";
        };
        "/nas/data" = {
          device = lib.mkDefault "nas.local:/volume1/data";
        };
        "/nas/media" = {
          device = lib.mkDefault "nas.local:/volume1/media";
        };
        "/nas/arr" = {
          device = lib.mkDefault "nas.local:/volume1/arr";
        };
      };
    })
    (lib.mkIf cfg.enable {
      networking.hosts = cfg.hosts;
      fileSystems = lib.mapAttrs' (name: mountConfig: {
        inherit name;
        value = {
          inherit (mountConfig) device;
          inherit (mountConfig) fsType;
          inherit (mountConfig) options;
        };
      }) config.local.system.nfs-mounts.mounts;
    })
  ];
}
