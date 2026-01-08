{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.direnv;
in
{
  options.local.apps.direnv = {
    enable = lib.mkEnableOption "Enable direnv";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.direnv = {
        enable = true;
        config = {
          global = {
            hide_env_diff = true;
            log_filter = "^$";
          };
        };

        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv;
        };
      };
    };
  };
}
