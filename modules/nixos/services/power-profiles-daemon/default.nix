{ lib, config, ... }:
let
  cfg = config.local.services.power-profiles-daemon;
in
{
  options.local.services.power-profiles-daemon = {
    enable = lib.mkEnableOption "Enable power profiles daemon";
  };

  config = lib.mkIf cfg.enable {
    services = {
      power-profiles-daemon.enable = true;
    };
  };
}
