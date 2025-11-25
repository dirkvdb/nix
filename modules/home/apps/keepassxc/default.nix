{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.keepassxc;

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
  options.local.home-manager.keepassxc = {
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

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.keepassxc = {
        enable = true;
      };

      programs.git-credential-keepassxc = {
        enable = true;
      };

      # KeePassXC configuration to enable Secret Service by default
      # home.file = lib.mkIf pkgs.stdenv.isDarwin {
      #   "Library/Application Support/KeePassXC/keepassxc.ini".text = keepassxcConfig;
      # };

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
            "waybar.service" # ensure the tray icon can be shown
            "ssh-agent.service"
          ];
          Requires = [ "ssh-agent.service" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/sleep 2"
            "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --timeout=30"
            # browser integration cannot be enabled if the config file is read-only, so we make a writable copy
            # "${pkgs.coreutils}/bin/cp %h/.config/keepassxc/keepassxc.immutable.ini %h/.config/keepassxc/keepassxc.ini"
            # "${pkgs.coreutils}/bin/chmod u+w %h/.config/keepassxc/keepassxc.ini"
          ];
          Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
          ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized --keyfile ${cfg.keyfilePath} ${lib.concatStringsSep " " cfg.databasePaths}";
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
