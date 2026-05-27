{
  config,
  pkgs,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.teams;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.teams = {
    enable = lib.mkEnableOption "Teams for Linux";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) (mkUserHome {
    xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
      appIconType = "light";
      disableGpu = false;
      enableIncomingCallToast = true;
    };
  });
}
