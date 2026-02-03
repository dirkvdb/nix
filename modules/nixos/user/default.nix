{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
in
{
  config = lib.mkIf user.enable {
    #local.system.shell.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
    #local.system.shell.zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;

    programs.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;

    environment.variables = {
      TERMINAL = "ghostty";
      VISUAL = "zeditor";
    };

    # systemd.user.extraConfig = ''
    #   DefaultEnvironment="PATH=/run/current-system/sw/bin"
    # '';

    users.groups.${user.name} = { };

    users.users.${user.name} = {
      isNormalUser = true;
      createHome = true;
      uid = 1000;
      group = "${user.name}";
      extraGroups = [
        "wheel"
        "hidraw"
        "i2c"
        "users"
        "video"
      ];
      shell = user.shell.package;
    };

  };
}
