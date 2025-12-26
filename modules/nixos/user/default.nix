{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  home-directory = "/home/${config.local.user.name}";
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
    #local.system.shell.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
    #local.system.shell.zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;

    programs.fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;

    environment.variables = {
      TERMINAL = "ghostty";
      EDITOR = "nvim";
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
