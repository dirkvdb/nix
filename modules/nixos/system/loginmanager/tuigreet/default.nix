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

    launchCmd = lib.mkOption {
      type = lib.types.str;
      description = "The command to launch the desired session";
      default = "hyprland";
      example = "hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      greetd = {
        enable = true;
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --remember --time --cmd '${cfg.launchCmd}'";
      };
    };
  };
}
