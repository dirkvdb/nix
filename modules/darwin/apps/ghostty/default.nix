{
  lib,
  config,
  ...
}:
let
  cfg = config.local.apps.ghostty;
in
{
  config = lib.mkIf cfg.enable {
    homebrew.casks = [
      "ghostty"
    ];
  };
}
