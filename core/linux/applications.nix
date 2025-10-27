{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixCfg.applications.gui = lib.mkEnableOption "GUI applications";

  config = lib.mkIf config.nixCfg.applications.gui {
    environment.systemPackages = with pkgs; [
      ghostty
      nautilus
      glib # for gsettings to work
      gsettings-qt
      gtk-engine-murrine # for gtk themes
    ];
  };
}
