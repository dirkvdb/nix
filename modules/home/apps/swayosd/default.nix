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
    services.swayosd = {
      enable = true;
    };

    xdg.configFile."swayosd/style.css".text = builtins.toString ''
      @define-color background-color ${theme.uiBaseColor};
      @define-color border-color ${theme.uiAccentColor};
      @define-color label ${theme.uiAccentColor};
      @define-color image ${theme.uiAccentColor};
      @define-color progress ${theme.uiAccentColor};

      window {
          border-radius: 8px;
          opacity: 0.97;
          border: 2px solid @border-color;

          background-color: @background-color;
      }

      label {
          font-family: "CaskaydiaMono Nerd Font";
          font-size: 11pt;

          color: @label;
      }

      image {
          color: @image;
      }

      progressbar {
          border-radius: 0;
      }

      progress {
          background-color: @progress;
      }
    '';
  };
}
