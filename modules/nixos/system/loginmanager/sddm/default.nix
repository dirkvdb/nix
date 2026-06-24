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

  # Custom weston.ini with [output] section so SDDM greeter appears on the chosen display
  westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
    libinput = {
      enable-tap = config.services.libinput.mouse.tapping;
      left-handed = config.services.libinput.mouse.leftHanded;
    };
    keyboard = {
      keymap_model = config.services.xserver.xkb.model;
      keymap_layout = config.services.xserver.xkb.layout;
      keymap_variant = config.services.xserver.xkb.variant;
      keymap_options = config.services.xserver.xkb.options;
    };
    output = {
      name = cfg.display;
      "app-ids" = "sddm-greeter-qt6";
    };
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

    display = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Connector name of the display to show SDDM on (e.g. 'DP-1', 'HDMI-A-1'). When set, a kwinoutputconfig.json is created for the sddm user so the greeter appears on this display.";
      default = null;
      example = "DP-1";
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

        # Override the compositor command with a custom weston.ini that
        # includes an [output] section for the chosen display.
        # TODO: Remove this when there is a nixos option to set the SDDM display output directly.
        settings.Wayland.CompositorCommand = lib.mkIf (
          cfg.display != null
        ) "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
      };
    };
  };
}
