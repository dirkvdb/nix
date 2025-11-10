{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.brave;
in
{
  options.local.apps.brave = {
    enable = lib.mkEnableOption "Install Brave browser";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      brave
    ];
  };
}
