{
  lib,
  config,
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
    programs = {
      localsend.enable = true;
    };
  };
}
