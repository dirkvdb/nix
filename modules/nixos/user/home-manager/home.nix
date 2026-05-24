{
  user,
  config,
  ...
}:
{
  imports = [
    ./scripts/linux.nix
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
    };
  };
}
