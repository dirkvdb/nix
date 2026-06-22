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

    autologin = {
      enable = lib.mkEnableOption "Auto-login on first boot (tuigreet as fallback on session exit)";
      user = lib.mkOption {
        type = lib.types.str;
        description = "The username to auto-login as";
      };
      command = lib.mkOption {
        type = lib.types.str;
        default = "uwsm start hyprland-uwsm.desktop";
        description = "The session command for the initial auto-login";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      restart = !cfg.autologin.enable;
      settings = {
        default_session.command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --remember --remember-session --time --sessions /run/current-system/sw/share/wayland-sessions --session-wrapper 'systemd-cat -t session'";
        initial_session = lib.mkIf cfg.autologin.enable {
          command = cfg.autologin.command;
          user = cfg.autologin.user;
        };
      };
    };
  };
}
