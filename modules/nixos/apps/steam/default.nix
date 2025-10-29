{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.steam;

in
{
  options.local.apps.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
