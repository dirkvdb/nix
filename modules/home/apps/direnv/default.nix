{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.direnv;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.direnv = {
    enable = lib.mkEnableOption "Enable direnv";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
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
  });
}
