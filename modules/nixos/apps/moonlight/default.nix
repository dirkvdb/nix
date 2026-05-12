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
  options.local.apps.moonlight = {
    enable = lib.mkEnableOption "Moonlight game streaming client";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
