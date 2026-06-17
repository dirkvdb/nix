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
  isNvidia = config.local.system.video.nvidia.enable or false;
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
          "tray.target"
        ];
        Wants = [ "graphical-session.target" ];
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
          outlook-for-linux
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
        systemd.user.services.officework-teams = graphicalService {
          description = "Microsoft Teams (teams-for-linux)";
          execStart = "${pkgs.teams-for-linux}/bin/teams-for-linux --minimized";
        };

        systemd.user.services.officework-slack = graphicalService {
          description = "Slack";
          execStart = "${pkgs.slack}/bin/slack --startup";
        };

        systemd.user.services.officework-outlook =
          lib.recursiveUpdate
            (graphicalService {
              description = "Outlook for Linux";
              execStart = "${pkgs.outlook-for-linux}/bin/outlook-for-linux --minimized";
            })
            (
              lib.optionalAttrs isNvidia {
                # WebKitGTK's DMA-BUF renderer breaks on NVIDIA proprietary drivers,
                # causing washed-out / garbled rendering. Disable it so WebKit falls
                # back to SHM-based compositing.
                Service.Environment = [ "WEBKIT_DISABLE_DMABUF_RENDERER=1" ];
              }
            );
      })
    ]
  );
}
