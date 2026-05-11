{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.fonts;
  gothamFonts = pkgs.stdenvNoCC.mkDerivation {
    name = "gotham-fonts";
    src = ./.;
    installPhase = ''
      install -Dm644 "Gotham Black Regular.ttf" "$out/share/fonts/truetype/Gotham Black Regular.ttf"
      install -Dm644 "Gotham Bold Regular.ttf" "$out/share/fonts/truetype/Gotham Bold Regular.ttf"
      install -Dm644 "Gotham Medium.otf" "$out/share/fonts/opentype/Gotham Medium.otf"
    '';
  };
in
{
  options.local.system.fonts = {
    enable = lib.mkEnableOption "Enable additional fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        gothamFonts
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.caskaydia-mono
        nerd-fonts.roboto-mono
        iosevka
        inter-nerdfont
        cascadia-code
        fira-sans
        fira-code
        monaspace
        noto-fonts
        noto-fonts-color-emoji
        roboto
        ubuntu-sans
        ubuntu-sans-mono
      ];
    };
  };
}
