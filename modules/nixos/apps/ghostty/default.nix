{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.ghostty;
in
{
  options.local.apps.ghostty = {
    enable = lib.mkEnableOption "Ghostty";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ghostty
    ];
  };
}
