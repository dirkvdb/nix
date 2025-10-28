{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixCfg.desktop;
in
{
  options.nixCfg.desktop = {
    enable = lib.mkEnableOption "desktop requirements";
  };

  config = lib.mkIf cfg.enable {
    # For regular login
    # security.pam.services.login.enableGnomeKeyring = true;
    # For display managers:
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Enable XDG portal for screen sharing, file pickers, etc.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };

    environment.systemPackages = with pkgs; [
      glib # for gsettings to work
      gsettings-qt
      gtk-engine-murrine # for gtk themes
      tela-icon-theme
    ];

    services = {
      gvfs.enable = true; # Nautilus
      devmon.enable = true; # automatic device mounting daemon
      udisks2.enable = true; # DBus service that allows applications to query and manipulate storage devices
      # upower.enable = true; # D-Bus service for power management.
      # power-profiles-daemon.enable = true;

      gnome = {
        gnome-keyring.enable = true;
        sushi.enable = true; # a quick previewer for nautilus
      };
    };

  };
}
