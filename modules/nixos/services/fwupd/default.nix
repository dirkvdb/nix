{ lib, config, ... }:
let
  cfg = config.local.services.fwupd;
in
{
  options.local.services.fwupd = {
    enable = lib.mkEnableOption "Enable firmware update service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      fwupd.enable = true;
    };
  };
}
