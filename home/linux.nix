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

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = with pkgs; [
      bitwarden
      sqlitebrowser

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
}
