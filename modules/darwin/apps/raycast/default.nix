{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.raycast;
in
{
  options.local.apps.raycast = {
    enable = lib.mkEnableOption "Install Raycast app launcher";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        raycast
      ];
    };
  };
}
