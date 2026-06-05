{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.keepassxc;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;

  keepassxcConfig = ''
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
    IconDownloadFallback=true
    LockDatabaseIdle=false
    LockDatabaseMinimize=false
    LockDatabaseScreenLock=false

    [Browser]
    CustomProxyLocation=
    Enabled=true
  '';
in
{
  options.local.apps.keepassxc = {
    enable = lib.mkEnableOption "Keepassxc password/secret manager.";

    databasePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Locations of the KeePassXC database files.";
      example = [ "%h/.local/share/secrets/Desktop.kdbx" ];
      default = [ ];
    };

    keyfilePath = lib.mkOption {
      type = lib.types.str;
      description = "Location of the keyfile.";
      example = "%h/.local/share/secrets/keyfile.key";
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.keepassxc = {
      enable = true;
    };

    programs.git-credential-keepassxc = {
      enable = true;
    };

    xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
      "keepassxc/keepassxc.ini".text = keepassxcConfig;
    };

    # Systemd user service for KeePassXC with Secret Service
    # KeePassXC will register org.freedesktop.secrets on D-Bus once running
    systemd.user.services.keepassxc = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "KeePassXC password manager with Secret Service";
        After = [
          "graphical-session.target"
          "tray.target"
          "ssh-agent.service"
        ];
        Wants = [ "tray.target" ];
        Requires = [ "ssh-agent.service" ];
        PartOf = [ "graphical-session.target" ];
        # Only start when a Wayland compositor is running (guards against
        # activation before UWSM has exported the display variables).
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "simple";
        Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
        ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized --keyfile ${cfg.keyfilePath} ${lib.concatStringsSep " " cfg.databasePaths}";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  });
}
