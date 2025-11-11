{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  hasDesktop = config.local.desktop.enable or false;
in
{
  config = lib.mkIf hasDesktop {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [
        nwg-look # tool to inspect the gtk settings
      ];

      gtk = {
        enable = true;

        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };

        iconTheme = {
          name = "Tela nord";
          package = pkgs.tela-icon-theme;
        };

        font = {
          name = "Ubuntu Sans Bold";
          size = 10;
        };

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };

        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark"; # many non-GNOME GTK apps still honor this
          font-name = "Ubuntu Sans Bold 10";
          monospace-font-name = "Caskaydia Mono Nerd Font 11";
          icon-theme = "Tela nord";
          cursor-theme = "macOS";
          cursor-size = 24;
        };
      };
    };
  };
}
