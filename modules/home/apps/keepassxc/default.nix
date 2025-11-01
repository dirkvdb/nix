{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.keepassxc;
in
{
  options.local.home-manager.keepassxc = {
    enable = lib.mkEnableOption "Keepassxc password/secret manager.";

    databasePath = lib.mkOption {
      type = lib.types.str;
      description = "Location of the KeePassXC database file.";
      example = "%h/.local/share/secrets/Desktop.kdbx";
    };

    keyfilePath = lib.mkOption {
      type = lib.types.str;
      description = "Location of the keyfile.";
      example = "%h/.local/share/secrets/keyfile.key";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.keepassxc = {
        enable = true;
      };

      # KeePassXC configuration to enable Secret Service by default
      xdg.configFile."keepassxc/keepassxc.ini".text = ''
        [FdoSecrets]
        Enabled=true
        ConfirmAccessItem=false
        ConfirmDeleteItem=false

        [SSHAgent]
        Enabled=true
        UseOpenSSH=true

        [GUI]
        MinimizeOnClose=true
        MinimizeOnStartup=true
        MinimizeToTray=true
        ShowTrayIcon=true
        TrayIconAppearance=monochrome-light

        [General]
        ConfigVersion=2
        RememberLastDatabases=true
        RememberLastKeyFiles=true
        OpenPreviousDatabasesOnStartup=true
        AutoSaveAfterEveryChange=true
        AutoSaveOnExit=true

        [Security]
        IconDownloadFallbackToGoogle=false
        LockDatabaseIdle=false
        LockDatabaseMinimize=false
        LockDatabaseScreenLock=false
      '';

      # Systemd user service for KeePassXC with Secret Service
      # KeePassXC will register org.freedesktop.secrets on D-Bus once running
      systemd.user.services.keepassxc = {
        Unit = {
          Description = "KeePassXC password manager with Secret Service";
          After = [
            "graphical-session.target"
            "waybar.service" # ensure the tray icon can be shown
            "ssh-agent.service"
          ];
          Requires = [ "ssh-agent.service" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
          ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized --keyfile ${cfg.keyfilePath} ${cfg.databasePath}";
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
