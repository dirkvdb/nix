{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.vivaldi;
in
{
  options.local.apps.vivaldi = {
    enable = lib.mkEnableOption "Install Vivaldi";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vivaldi
    ];
  };
}
