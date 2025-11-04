{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop;
in
{
  options.local.desktop = {
    enable = lib.mkEnableOption "Enable desktop environment support";
  };

  config = lib.mkIf cfg.enable {
    # Enable polkit for privilege escalation
    security.polkit.enable = true;

    qt = {
      enable = true;
      platformTheme = "gtk2";
      style = "adwaita-dark";
    };

    environment.systemPackages = with pkgs; [
      glib # for gsettings to work
      gsettings-qt
      gtk-engine-murrine # for gtk themes
      tela-icon-theme
      nautilus
      file-roller # archive manager
      notify-desktop # cmd for sending notifications
      ungoogled-chromium # needed for the web apps
    ];

    services = {
      gvfs.enable = true; # Nautilus
      devmon.enable = true; # automatic device mounting daemon
      udisks2.enable = true; # DBus service that allows applications to query and manipulate storage devices
      # upower.enable = true; # D-Bus service for power management.
      # power-profiles-daemon.enable = true;

      gnome = {
        sushi.enable = true; # a quick previewer for nautilus
      };
    };
  };
}
