{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.apps.localsend;
in
{
  options.local.apps.localsend = {
    enable = lib.mkEnableOption "Install LocalSend (cross platform AirDrop alternative)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      localsend
    ];
  };
}
