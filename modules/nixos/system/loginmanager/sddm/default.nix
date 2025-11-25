{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.loginmanager.sddm;
in
{
  options.local.system.loginmanager.sddm = {
    enable = lib.mkEnableOption "Enable the sddm graphical login manager";

    launchCmd = lib.mkOption {
      type = lib.types.str;
      description = "The command to launch the desired session";
      default = "hyprland";
      example = "hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager = {
      defaultSession = cfg.launchCmd;
      sddm = {
        enable = true;
        enableHidpi = true;
        wayland.enable = true;
      };
    };
  };
}
