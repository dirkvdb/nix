{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (config.local) user;
  home-directory = "/Users/${user.name}";

in
{
  options.local.user = {
    enable = lib.mkEnableOption "Enable User";
    name = lib.mkOption {
      type = lib.types.str;
      default = "dirk";
      description = "User account name";
    };

    alias = lib.mkOption {
      type = lib.types.str;
      default = "Dirk Vanden Boer";
      description = "Full alias";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "dirk.vdb@gmail.com";
      description = "Email address";
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "${home-directory}";
      description = "Home Directory Path";
    };

    home-manager.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable home-manager";
    };

    ghToken.enable = lib.mkEnableOption "Include GitHub access-tokens in nix.conf";

    shell = lib.mkOption {
      default = { };
      description = "Shell config for user";
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.fish;
            description = "User shell";
          };

          starship.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable starship";
          };
        };
      };
    };
  };

  config = lib.mkIf user.enable {
    system.primaryUser = "${user.name}";
    users.knownUsers = [ "${user.name}" ];

    users.users.${user.name} = {
      name = "${user.name}";
      home = "${user.homeDir}";
      isHidden = false;
      shell = user.shell.package;
      uid = 501;
      # openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
      # openssh.authorizedKeys.keys = [
      #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs"
      # ];
    };

    environment.shells = [
      user.shell.package
    ];

    local.system.shell.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
    local.system.shell.zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;
  };
}
