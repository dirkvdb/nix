{
  lib,
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
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
