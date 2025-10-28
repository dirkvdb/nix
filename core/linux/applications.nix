{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.nixCfg.applications.gui = lib.mkEnableOption "GUI applications";
  options.nixCfg.applications.dev = lib.mkEnableOption "Developer applications";

  config = lib.mkMerge [
    (lib.mkIf config.nixCfg.applications.gui {
      environment.systemPackages = with pkgs; [
        ghostty
        nautilus
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
