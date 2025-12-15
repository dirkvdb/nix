{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.slack;
in
{
  options.local.apps.slack = {
    enable = lib.mkEnableOption "Slack communication tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      slack
    ];
  };
}
