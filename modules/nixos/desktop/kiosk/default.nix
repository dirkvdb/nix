{
  lib,
  pkgs,
  unstablePkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop.kiosk;
in
{
  options.local.desktop.kiosk = {
    enable = lib.mkEnableOption "Enable kiosk desktop environment using cage";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.local.user.name;
      description = "The user to run the kiosk session as.";
    };

    program = lib.mkOption {
      type = lib.types.path;
      default = lib.getExe pkgs.es-de;
      description = "The program to run inside the cage kiosk session.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # -d: don't draw client-side decorations (cleaner kiosk look)
      default = [ "-d" ];
      example = [ "-m last" ];
      description = "Extra arguments passed to cage.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        # Don't error if no input devices are detected at startup
        WLR_LIBINPUT_NO_DEVICES = "1";
      };
      description = "Additional environment variables for the cage session.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cage = {
      enable = true;
      user = cfg.user;
      program = cfg.program;
      extraArguments = cfg.extraArgs;
      environment = cfg.environment;
      # Use cage from unstable; may have a fix for XWayland/bwrap issues.
      package = unstablePkgs.cage;
    };

    environment.systemPackages = [ pkgs.es-de ];
  };
}
