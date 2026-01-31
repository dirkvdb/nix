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
    system.primaryUser = "${user.name}";
    users.knownUsers = [ "${user.name}" ];

    users.users.${user.name} = {
      name = "${user.name}";
      home = "${user.homeDir}";
      isHidden = false;
      shell = user.shell.package;
      uid = 501;
    };

    environment.shells = [
      user.shell.package
    ];

    local.system.shell.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
    local.system.shell.zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;
  };
}
