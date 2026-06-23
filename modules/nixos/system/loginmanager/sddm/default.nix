{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.loginmanager.sddm;
  displayScale = config.local.desktop.displayScale;
  scale = toString displayScale;
  dpi = toString (builtins.floor (96 * displayScale));
  silentPkg = config.programs.silentSDDM.package';
in
{
  options.local.system.loginmanager.sddm = {
    enable = lib.mkEnableOption "Enable the sddm graphical login manager";

    launchCmd = lib.mkOption {
      type = lib.types.str;
      description = "The command to launch the desired session";
      default = "hyprland-uwsm";
      example = "hyprland";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      description = "SilentSDDM theme preset to use (e.g. 'default', 'rei', 'everforest', 'catppuccin-mocha')";
      default = "everforest";
      example = "rei";
    };

    autologin = {
      enable = lib.mkEnableOption "Auto-login (useful when LUKS already provides authentication)";
      user = lib.mkOption {
        type = lib.types.str;
        description = "The username to auto-login as";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.silentSDDM = {
      enable = true;
      theme = cfg.theme;
    };

    services.displayManager = {
      defaultSession = cfg.launchCmd;
      
      autoLogin = lib.mkIf cfg.autologin.enable {
        enable = true;
        user = cfg.autologin.user;
      };

      sddm = {
        enable = true;
        enableHidpi = true;
        wayland.enable = true;

        # Don't restart SDDM after logout when autologin is active;
        # the greeter will show normally on session exit.
        autoLogin.relogin = lib.mkIf cfg.autologin.enable false;

        # The SilentSDDM module sets GreeterEnvironment without a scale
        # factor.  Qt-based Wayland greeters need QT_SCREEN_SCALE_FACTORS
        # for HiDPI to actually take effect, so override the value here.
        settings.General.GreeterEnvironment = lib.mkForce "QML2_IMPORT_PATH=${silentPkg}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard,QT_SCREEN_SCALE_FACTORS=${scale},QT_FONT_DPI=${dpi}";
      };
    };
  };
}
