{
  pkgs,
  system,
  inputs,
  userConfig,
  ...
}: {
  imports = [
    ./core.nix
    ./applications/hyprland.nix
    ./scripts/linux.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = with pkgs; [
      bitwarden
      sqlitebrowser
    ];
  };
}
