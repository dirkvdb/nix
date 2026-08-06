{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.boot.disk-encryption;

  # Names of the `/dev/mapper/luks-*` devices actually referenced by the
  # generated hardware configuration (root, swap, ...).
  #
  # These are derived from the static device strings in `fileSystems` and
  # `swapDevices`, so there is no dependency cycle with `boot.initrd.luks.devices`
  # itself. Deriving the names this way keeps the SSD tuning correct across
  # reinstalls, which produce fresh LUKS UUIDs (and therefore new mapper names).
  referencedDevices =
    (lib.mapAttrsToList (_: fs: fs.device or null) config.fileSystems)
    ++ (map (s: s.device or null) config.swapDevices);

  luksMapperNames = lib.pipe referencedDevices [
    (lib.filter (d: d != null && lib.hasPrefix "/dev/mapper/luks-" d))
    (map (lib.removePrefix "/dev/mapper/"))
    lib.unique
  ];
in
{
  options.local.system.boot.disk-encryption = {
    enable = lib.mkEnableOption "Enable LUKS full disk encryption";

    device = lib.mkOption {
      type = lib.types.str;
      description = "Path to the underlying LUKS partition (e.g. /dev/disk/by-label/NIXROOT_CRYPT or a UUID path)";
    };

    ssdOptimize = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apply SSD-friendly options to every LUKS device referenced by the file
        systems and swap:

        - `allowDiscards`: pass TRIM/discard through the encryption layer so the
          SSD can reclaim deleted blocks, preserving write performance.
        - `bypassWorkqueues`: skip dm-crypt's internal workqueues and submit
          crypto ops directly, avoiding needless context switches on NVMe which
          already has efficient multi-queue I/O scheduling.

        The affected devices are derived from the active mapper names rather than
        hardcoded UUIDs, so the tuning stays correct across reinstalls that
        produce new LUKS UUIDs.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot.initrd.luks.devices."cryptroot" = {
        device = cfg.device;
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    })

    (lib.mkIf cfg.ssdOptimize {
      boot.initrd.luks.devices = lib.genAttrs luksMapperNames (_: {
        allowDiscards = true;
        bypassWorkqueues = true;
      });
    })
  ];
}
