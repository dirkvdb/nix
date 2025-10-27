{
  pkgs,
  ...
}:
{
  imports = [
    ./linux/applications.nix
  ];

  environment.systemPackages = with pkgs; [
    bitwarden
    sqlitebrowser
    sublime-merge
    spotify
  ];
}
