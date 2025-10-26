{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.applications.gui = lib.mkEnableOption "GUI applications";

  config = lib.mkIf config.applications.gui {
    environment.systemPackages = with pkgs; [
      ghostty
      nautilus
      glib # for gsettings to work
      gsettings-qt
      gtk-engine-murrine # for gtk themes
    ];
  };
}
