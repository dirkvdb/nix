{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.spotify;
in
{
  options.local.apps.spotify = {
    enable = lib.mkEnableOption "Install Spotify desktop app";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spotify
    ];
  };
}
