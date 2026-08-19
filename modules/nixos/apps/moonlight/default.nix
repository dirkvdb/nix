{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.moonlight;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.moonlight-qt ];
  };
}
