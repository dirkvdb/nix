{
  pkgs,
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.local.cli-tools.just;

in
{
  options.local.cli-tools.just = {
    enable = mkEnableOption "Enable just, its like make but more straight forward";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      just
    ];
  };
}
