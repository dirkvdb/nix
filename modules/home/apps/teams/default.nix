{
  config,
  pkgs,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.teams;
  mkUserHome = mkHome user.name;
in
{
  options.local.home-manager.teams = {
    enable = lib.mkEnableOption "Teams for Linux";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) (mkUserHome {
    xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
      appIconType = "light";
    };
  });
}
