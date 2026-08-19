{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.services.officework;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      teams-for-linux
      slack
    ];
  };
}
