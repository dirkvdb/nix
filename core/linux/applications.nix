{
  pkgs,
  lib,
  config,
  ...
}:
{

  config = lib.mkMerge [
    (lib.mkIf config.nixCfg.applications.gui {
      environment.systemPackages = with pkgs; [
        ghostty
        nautilus
        notify-desktop # cmd for sending notifications
        glib # for gsettings to work
        gsettings-qt
        gtk-engine-murrine # for gtk themes
        ungoogled-chromium
      ];
    })

    (lib.mkIf config.nixCfg.applications.dev {
      environment.systemPackages = with pkgs; [
        mise
        just
      ];
    })
  ];
}
