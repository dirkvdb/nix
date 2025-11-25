{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
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

        # theme = {
        #   name = theme.gtkTheme;
        #   package = theme.gtkThemePackage;
        # };

        # iconTheme = {
        #   name = theme.iconTheme;
        #   package = theme.iconThemePackage;
        # };

        # font = {
        #   name = theme.uiFont;
        #   size = theme.uiFontSize;
        # };

        # gtk3.extraConfig = {
        #   gtk-application-prefer-dark-theme = true;
        # };

        # gtk4.extraConfig = {
        #   gtk-application-prefer-dark-theme = true;
        # };
      };

      # dconf.settings = {
      #   "org/gnome/desktop/interface" = {
      #     color-scheme = "prefer-dark";
      #   };
      # };
    };
  };
}
