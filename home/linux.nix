{
  pkgs,
  config,
  system,
  userConfig,
  elephant,
  zen-browser,
  walker,
  ...
}:
{
  imports = [
    ./core.nix
    ./applications/hyprland.nix
    ./applications/zen.nix
    ./applications/webapps.nix
    ./scripts/linux.nix
    walker.homeManagerModules.default
    zen-browser.homeModules.default
  ];

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.userDirs.download = "${config.home.homeDirectory}/downloads";
  xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
  xdg.userDirs.documents = "${config.home.homeDirectory}/docs";
  xdg.userDirs.desktop = null;
  xdg.userDirs.templates = null;
  xdg.userDirs.publicShare = null;
  xdg.userDirs.videos = null;
  xdg.userDirs.music = null;

  xdg.configFile."mako".source = ./dotfiles/mako;
  xdg.dataFile."theme" = {
    source = ./themes/${userConfig.theme};
    recursive = true;
  };

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = [
      # Elephant with all providers for walker
      elephant.packages.${system}.elephant-with-providers
    ];

    pointerCursor = {
      package = pkgs.apple-cursor;
      name = "macOS";
      size = 24;
      gtk.enable = true;
    };
  };

  # Configure walker from flake
  programs.walker = {
    enable = true;
    runAsService = true;
  };

  # Password manager with Secret Service support
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
      ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized --keyfile %h/.local/share/secrets/desktop %h/.local/share/secrets/Desktop.kdbx";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
