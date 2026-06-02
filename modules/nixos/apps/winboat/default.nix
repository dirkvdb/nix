{
  lib,
  unstablePkgs,
  config,
  ...
}:
let
  cfg = config.local.apps.winboat;
in
{
  options.local.apps.winboat = {
    enable = lib.mkEnableOption "winboat Windows VM bridge tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      unstablePkgs.winboat
    ];
  };
}
