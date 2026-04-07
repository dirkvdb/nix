{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.celluloid;
in
{
  options.local.apps.celluloid = {
    enable = lib.mkEnableOption "celluloid";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.celluloid.override { youtubeSupport = false; })
    ];
  };
}
