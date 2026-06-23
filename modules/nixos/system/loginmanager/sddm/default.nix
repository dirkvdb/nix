{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.local.system.loginmanager.sddm;
  displayScale = config.local.desktop.displayScale;
  scale = toString displayScale;
  dpi = toString (builtins.floor (96 * displayScale));
  silentPkg = config.programs.silentSDDM.package';
  font = config.stylix.fonts.sansSerif.name;
  colors = config.lib.stylix.colors;

  # Custom preset with stylix colors and font substituted
  customConf = pkgs.replaceVars ./theme.conf {
    inherit font;
    base00 = colors.base00-hex;
    base01 = colors.base01-hex;
    base02 = colors.base02-hex;
    base05 = colors.base05-hex;
    base08 = colors.base08-hex;
    base0A = colors.base0A-hex;
    base0E = colors.base0E-hex;
  };

  # The base SilentSDDM package from the flake input (avoids infinite recursion)
  silentBase = inputs.silent-sddm.packages.${pkgs.system}.default;
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

    defaultUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Pre-select this user on the login screen so the password field is immediately focused";
      default = null;
      example = "dirk";
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
      backgrounds.wallpaper11 = ../../../../common/theme/wallpapers/wallpaper11.jpg;
      # Replace the default package with one that uses our custom stylix-themed config
      package = silentBase.overrideAttrs (old: {
        installPhase = old.installPhase + ''
          cp -f ${customConf} $out/share/sddm/themes/silent/configs/${cfg.theme}.conf
        '';
      });
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

        settings.Users.DefaultUser = lib.mkIf (cfg.defaultUser != null) cfg.defaultUser;
      };
    };
  };
}
