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
  ];

  # Copy scripts to ~/.local/bin
  home.file.".local/bin" = {
    source = ../scripts/linux;
    recursive = true;
    executable = true;
  };

  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";

    packages = with pkgs; [
      bitwarden
      sqlitebrowser
    ];
  };
}
