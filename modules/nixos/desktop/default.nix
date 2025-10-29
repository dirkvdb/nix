{
  lib,
  config,
  ...
}:
let
  cfg = config.local.desktop;
in
{
  options.local.desktop = {
    enable = lib.mkEnableOption "Enable desktop environment support";
  };

  config = lib.mkIf cfg.enable {
    # Enable polkit for privilege escalation
    security.polkit.enable = true;
  };
}
