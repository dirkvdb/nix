{
  lib,
  config,
  mkHome,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.tether;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.tether = {
    enable = lib.mkEnableOption "Tether iPhone integration";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) (mkUserHome {
    home.packages = [ pkgs.tether ];

    systemd.user.services.tetherd = {
      Unit = {
        Description = "Tether iPhone integration daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStart = "${pkgs.tether}/bin/tetherd";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  });
}
