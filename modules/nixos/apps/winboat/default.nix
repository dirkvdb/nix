{
  lib,
  pkgs,
  unstablePkgs,
  config,
  ...
}:
let
  cfg = config.local.apps.winboat;
in
{
  options.local.apps.winboat = {
    enable = lib.mkEnableOption "winboat Windows VM bridge tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      unstablePkgs.winboat
    ];

    # Prevent the WinBoat Docker container from starting automatically at boot.
    # WinBoat sets a restart policy of "on-failure" by default; override it to
    # "no" so the container only runs when explicitly started via the app.
    systemd.services.winboat-no-autostart = {
      description = "Disable WinBoat Docker container autostart";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.docker}/bin/docker update --restart=no WinBoat";
      };
    };
  };
}
