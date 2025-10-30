{
  pkgs,
  config,
  system,
  userConfig,
  elephant,
  zen-browser,
  walker,
  ...
}:
{
  imports = [
    ./core.nix
    ./applications/hyprland.nix
    ./applications/zen.nix
    ./applications/webapps.nix
    ./scripts/linux.nix
    walker.homeManagerModules.default
    zen-browser.homeModules.default
  ];

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

  xdg.configFile."mako".source = ./dotfiles/mako;
  xdg.dataFile."theme" = {
    source = ./themes/${userConfig.theme};
    recursive = true;
  };

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = [
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

  # Configure walker from flake
  programs.walker = {
    enable = true;
    runAsService = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
