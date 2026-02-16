{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.zellij;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.zellij = {
    enable = lib.mkEnableOption "Termnal workspace manager";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.zellij = {
      enable = true;
    };
  });
}
