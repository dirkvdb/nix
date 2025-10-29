{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.firefox;
in
{
  options.local.apps.firefox = {
    enable = lib.mkEnableOption "Install Firefox";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      firefox
    ];
  };
}
