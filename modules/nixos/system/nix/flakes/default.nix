{
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.local.system.nix.flakes;

in
{
  options.local.system.nix.flakes = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
