{
  lib,
  config,
  ...
}:
let
  cfg = config.local.apps.bitwarden;
in
{
  options.local.apps.bitwarden = {
    enable = lib.mkEnableOption "Install Bitwarden desktop app";
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      casks = [
        "bitwarden"
      ];
    };
  };
}
