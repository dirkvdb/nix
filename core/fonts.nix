{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.nixCfg.fonts;
in
{
  # fonts.enable option declared in core/default.nix

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.caskaydia-mono
        nerd-fonts.roboto-mono
        fira-code
        monaspace
        cascadia-code
      ];
    };
  };
}
