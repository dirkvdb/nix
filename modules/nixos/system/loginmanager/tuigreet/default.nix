{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.loginmanager.tuigreet;
in
{
  options.local.system.loginmanager.tuigreet = {
    enable = lib.mkEnableOption "Enable the tuigreet login manager";
  };

  config = lib.mkIf cfg.enable {
    services = {
      greetd = {
        enable = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --remember --remember-session --time --sessions /run/current-system/sw/share/wayland-sessions --session-wrapper 'systemd-cat -t session'";
      };
    };
  };
}
