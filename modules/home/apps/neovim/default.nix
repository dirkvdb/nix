{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.neovim;
in
{
  options.local.apps.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.neovim = {
        enable = true;
      };
    };
  };
}
