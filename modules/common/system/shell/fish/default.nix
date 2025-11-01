{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.shell.fish;
in
{
  options.local.system.shell.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
    };
  };
}
