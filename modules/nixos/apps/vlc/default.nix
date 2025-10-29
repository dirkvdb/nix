{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.vlc;
in
{
  options.local.apps.vlc = {
    enable = lib.mkEnableOption "vlc";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.vlc
    ];
  };
}
