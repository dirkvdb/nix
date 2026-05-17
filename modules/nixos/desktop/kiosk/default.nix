{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop.kiosk;
  gamescopeArgs = lib.concatStringsSep " " cfg.gamescopeArgs;
  steamArgs = lib.concatStringsSep " " cfg.steamArgs;
  command = "${lib.getExe pkgs.gamescope} ${gamescopeArgs} -- steam ${steamArgs} > /dev/null 2>&1";
in
{
  options.local.desktop.kiosk = {
    enable = lib.mkEnableOption "Enable kiosk/TV desktop environment using gamescope";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.local.user.name;
      description = "The user to run the kiosk session as.";
    };

    gamescopeArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-W 1920"
        "-H 1080"
        "-f"
        "-e"
        "--xwayland-count 2"
      ];
      description = "Arguments passed to gamescope.";
    };

    steamArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-pipewire-dmabuf"
        "-gamepadui"
      ];
      description = "Arguments passed to Steam inside gamescope.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    programs.steam.gamescopeSession.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          inherit command;
          user = cfg.user;
        };
      };
    };
  };
}
