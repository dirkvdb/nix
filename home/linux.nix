{
  pkgs,
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
    ./scripts/linux.nix
    walker.homeManagerModules.default
    zen-browser.homeModules.default
  ];

  xdg.configFile."mako".source = ./dotfiles/mako;

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = with pkgs; [
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
