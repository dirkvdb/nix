{ lib, config, ... }:
let
  cfg = config.local.system.nfs-mounts;
in
{
  options.local.system.nfs-mounts = {
    enable = lib.mkEnableOption "NFS mounts";
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
              ];
              description = "Default mount options";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = lib.mapAttrs' (name: mountConfig: {
      inherit name;
      value = {
        inherit (mountConfig) device;
        inherit (mountConfig) fsType;
        inherit (mountConfig) options;
      };
    }) config.local.system.nfs-mounts.mounts;
  };
}
