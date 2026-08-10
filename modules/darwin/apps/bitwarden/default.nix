{
  lib,
  config,
  ...
}:
let
  cfg = config.local.apps.bitwarden;
in
{
  config = lib.mkIf cfg.enable {
    homebrew = {
      casks = [
        "bitwarden"
      ];
    };
  };
}
