{
  pkgs,
  userConfig,
  ...
}:
{
  nix = {
    settings = {
      trusted-users = [
        "root"
        userConfig.username
      ];
    };
  };

  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.username;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "hidraw"
      "i2c"
      "video"
    ];
  };
  users.groups.hidraw = { };

  programs = {
    fish.enable = true;
    firefox.enable = true;
  };

}
