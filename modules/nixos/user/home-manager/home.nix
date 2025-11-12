{
  pkgs,
  lib,
  system,
  user,
  config,
  elephant,
  walker,
  theme,
  isDesktop,
  ...
}:
{
  imports = [
    ./scripts/linux.nix
  ] ++ lib.optionals isDesktop [
    walker.homeManagerModules.default
  ];

  config = {
    programs.home-manager.enable = true;
    xdg.userDirs.enable = true;
    xdg.userDirs.createDirectories = true;
    xdg.userDirs.download = "${config.home.homeDirectory}/downloads";
    xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
    xdg.userDirs.documents = "${config.home.homeDirectory}/docs";
    xdg.userDirs.desktop = null;
    xdg.userDirs.templates = null;
    xdg.userDirs.publicShare = null;
    xdg.userDirs.videos = null;
    xdg.userDirs.music = null;

    home = {
      username = "${user.name}";
      stateVersion = "25.05";
      homeDirectory = "${user.homeDir}";

      packages = lib.optionals isDesktop [
        # Elephant with all providers for walker
        elephant.packages.${system}.elephant-with-providers
      ];

      pointerCursor = {
        package = pkgs.apple-cursor;
        name = "macOS";
        size = 24;
        gtk.enable = true;
      };
    };

    xdg.configFile."mako".source = ../../../home/dotfiles/mako;
    xdg.dataFile."theme" = {
      source = ../../../home/themes/${theme.name};
      recursive = true;
    };
  } // lib.optionalAttrs isDesktop {
    programs.walker = {
      enable = true;
      runAsService = true;
    };
  };
}
