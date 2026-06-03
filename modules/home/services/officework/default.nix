{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.officework;
  mkUserHome = mkHome user.name;

  graphicalService =
    {
      description,
      execStart,
    }:
    {
      Unit = {
        Description = description;
        After = [
          "graphical-session.target"
          "waybar.service"
        ];
        Wants = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = execStart;
        Restart = "no";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
in
{
  options.local.services.officework = {
    enable = lib.mkEnableOption "officework — auto-start work applications (Teams, Slack, Outlook)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          teams-for-linux
          slack
          outlook-for-linux
        ];
      }
      (mkUserHome {
        systemd.user.services.officework-teams = graphicalService {
          description = "Microsoft Teams (teams-for-linux)";
          execStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --minimized";
        };

        systemd.user.services.officework-slack = graphicalService {
          description = "Slack";
          execStart = "${pkgs.slack}/bin/slack --startup";
        };

        systemd.user.services.officework-outlook = graphicalService {
          description = "Outlook for Linux";
          execStart = "${pkgs.outlook-for-linux}/bin/outlook-for-linux";
        };
      })
    ]
  );
}
