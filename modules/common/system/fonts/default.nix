{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.fonts;
in
{
  options.local.system.fonts = {
    enable = lib.mkEnableOption "Enable additional fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.caskaydia-mono
        nerd-fonts.roboto-mono
        cascadia-code
        fira-sans
        fira-code
        monaspace
        noto-fonts
        noto-fonts-emoji
      ];
    };
  };
}
