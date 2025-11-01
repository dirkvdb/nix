{ lib, config, ... }:
let
  cfg = config.local.tools.homebrew;
in
{
  options.local.tools.homebrew = {
    enable = lib.mkEnableOption "Enable Homebrew";
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
      };
    };
  };
}
