{
  config,
  ...
}:
let
  inherit (config.local) user;
in
{
  home-manager.users.${user.name} = {
    services.mako = {
      enable = true;
      settings = {
        # include = "~/.local/share/theme/mako.ini";

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
          width = 215;
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
