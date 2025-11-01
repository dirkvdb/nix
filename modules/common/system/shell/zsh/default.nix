{ lib, config, ... }:
let
  cfg = config.local.system.shell.zsh;
in
{
  options.local.system.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell";
  };

  config = lib.mkIf cfg.enable {
    programs.zsh.enable = true;
  };
}
