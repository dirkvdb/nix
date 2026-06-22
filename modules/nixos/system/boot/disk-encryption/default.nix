{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.boot.disk-encryption;
in
{
  options.local.system.boot.disk-encryption = {
    enable = lib.mkEnableOption "Enable LUKS full disk encryption";

    device = lib.mkOption {
      type = lib.types.str;
      description = "Path to the underlying LUKS partition (e.g. /dev/disk/by-label/NIXROOT_CRYPT or a UUID path)";
    };

  };

  config = lib.mkIf cfg.enable {
    boot.initrd.luks.devices."cryptroot" = {
      device = cfg.device;
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };
}
