{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.nix.flakes;
in
{
  options.local.system.nix.flakes = {
    enable = lib.mkEnableOption "Enable Flakes";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
