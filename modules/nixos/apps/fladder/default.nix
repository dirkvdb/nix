{
  lib,
  config,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.fladder;
in
{
  options.local.apps.fladder = {
    enable = lib.mkEnableOption "fladder";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ unstablePkgs.fladder ];
  };
}
