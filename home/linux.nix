{
  pkgs,
  system,
  inputs,
  userConfig,
  elephant,
  walker,
  ...
}: {
  imports = [
    ./core.nix
    ./applications/hyprland.nix
    ./scripts/linux.nix
    walker.homeManagerModules.default
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
  };

  # Configure walker from flake
  programs.walker = {
    enable = true;
    runAsService = true;
  };
}
