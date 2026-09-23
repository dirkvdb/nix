{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.dev;
in
{
  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.platformio-core.udev ];
    services.udev.extraRules = builtins.readFile ./99-arduino-opta.rules;
  };
}
