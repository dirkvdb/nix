{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.bitwarden;
in
{
  options.local.apps.bitwarden = {
    enable = lib.mkEnableOption "Install Bitwarden desktop app";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bitwarden
    ];

    systemd.user.services.bitwarden = {
      description = "Autostart service for Bitwarden";
      documentation = [ "https://bitwarden.com" ];
      enable = true;
      partOf = [ "desktop.service" ];
      wantedBy = [ "desktop.service" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.bitwarden}";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
        Restart = "on-failure";
        RestartSec = "5s";
        KillMode = "mixed";
        SuccessExitStatus = "1";
      };
    };
  };
}
