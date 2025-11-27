{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
in
{
  home-manager.users.${user.name} = lib.mkIf (isLinux && isDesktop) {
    stylix.targets.mako.enable = false;

    services.mako = {
      enable = true;
      settings = {
        text-color = theme.uiAccentColor;
        border-color = theme.uiAccentColor;
        background-color = theme.uiBaseColor;

        anchor = "top-right";
        default-timeout = 5000;
        width = 420;
        outer-margin = 20;
        padding = "10,15";
        border-size = 2;
        border-radius = 8;
        max-icon-size = 32;
        #font="sans-serif 14px";

        "app-name=Spotify" = {
          invisible = 1;
        };

        "app-name=KeePassXC" = {
          anchor = "bottom-right";
          ignore-timeout = 1;
          default-timeout = 1500;
          width = 250;
          format = "<b>%s</b> Accessed a secret";
        };

        "mode=do-not-disturb" = {
          invisible = true;
        };

        "mode=do-not-disturb app-name=notify-send" = {
          invisible = false;
        };

        "urgency=critical" = {
          default-timeout = 0;
        };
      };
    };
  };
}
