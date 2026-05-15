{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.services.sunshine;
  esDeCfg = config.local.apps.retro-emulation;
in
{
  options.local.services.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming";
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;

      openFirewall = true;

      settings = {
        fps = 60;
        min_fps_factor = 1;
        channels = 2;
        output_name = 1;
        encoder = "vaapi";
      };

      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Desktop 2160p";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "hyprctl keyword monitor ,3840x2160@30,auto,1.66666667";
              undo = "hyprctl keyword monitor ,preferred,auto,${toString config.local.desktop.displayScale}";
            }
          ];
        }
        {
          name = "Desktop 1080p";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "hyprctl keyword monitor ,1920x1080@30,auto,1";
              undo = "hyprctl keyword monitor ,preferred,auto,${toString config.local.desktop.displayScale}";
            }
          ];
        }
      ]
      ++ lib.optionals esDeCfg.enable [
        {
          name = "ES-DE";
          detached = [ "${pkgs.es-de}/bin/es-de" ];
          image-path = "${../../apps/retro-emulation/esde.png}";
          prep-cmd = [
            {
              do = "hyprctl keyword monitor ,3840x2160@60,auto,1.4";
              undo = "hyprctl keyword monitor ,preferred,auto,${toString config.local.desktop.displayScale}";
            }
          ];
          auto-detach = "true";
        }
      ];
    };
  };
}
