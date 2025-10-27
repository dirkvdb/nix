{
  pkgs,
  ...
}:
{
  imports = pkgs.lib.optionals pkgs.stdenv.isLinux [
    ./linux/applications.nix
  ];

  environment.systemPackages = with pkgs; [
    bitwarden
    sqlitebrowser
    sublime-merge
    spotify
  ];
}
