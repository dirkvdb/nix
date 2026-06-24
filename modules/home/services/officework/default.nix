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

  # Use the final wrapped chromium from home-manager (includes commandLineArgs like proxy-pac-url)
  chromiumPkg = config.home-manager.users.${user.name}.programs.chromium.finalPackage;

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
          "tray.target"
          "keepassxc.service"
        ];
        Wants = [ "graphical-session.target" ];
        Requires = [ "keepassxc.service" ];
      };

      Service = {
        Type = "simple";
        ExecStart = execStart;
        Restart = "no";
      };

      Install = lib.mkIf cfg.autostart {
        WantedBy = [ "graphical-session.target" ];
      };
    };
in
{
  options.local.services.officework = {
    enable = lib.mkEnableOption "officework — auto-start work applications (Teams, Slack, Outlook)";

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the officework systemd user services start automatically with the graphical session.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          teams-for-linux
          slack
        ];
      }
      (mkUserHome {
        home.packages = [
          # Toggle all officework services
          (pkgs.writeShellScriptBin "nixcfg-toggle-officework" ''
            services="officework-teams.service officework-slack.service officework-outlook.service"
            if systemctl --user is-active --quiet officework-teams.service; then
              systemctl --user stop $services
              notify-desktop "Officework services stopped"
            else
              systemctl --user start $services
              notify-desktop "Officework services started"
            fi
          '')
        ];
      })
      (mkUserHome {
        systemd.user.services.officework-teams =
          lib.recursiveUpdate
            (graphicalService {
              description = "Microsoft Teams (teams-for-linux)";
              execStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --minimized";
            })
            {
              Service = {
                KillSignal = "SIGINT";
                TimeoutStopSec = 5;
              };
            };

        systemd.user.services.officework-slack = graphicalService {
          description = "Slack";
          execStart = "${pkgs.slack}/bin/slack --startup";
        };

        systemd.user.services.officework-outlook = graphicalService {
          description = "Outlook Web App";
          execStart = "${chromiumPkg}/bin/chromium --app=https://outlook.office365.com/ --restore-last-session";
        };
      })
    ]
  );
}
