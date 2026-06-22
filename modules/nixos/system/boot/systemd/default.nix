{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.boot.systemd;
in
{
  options.local.system.boot.systemd = {
    enable = lib.mkEnableOption "Enable systemd bootloader";
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot = {
        enable = true;
        consoleMode = lib.mkDefault "2"; # use 2 unless overridden elsewhere
        configurationLimit = lib.mkDefault 6;
      };
    };
  };
}
