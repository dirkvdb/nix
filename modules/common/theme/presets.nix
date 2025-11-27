{ pkgs }:
{
  everforest = {
    name = "everforest";
    base16Scheme = "everforest";
    gtkTheme = "Adwaita-dark";
    gtkThemePackage = pkgs.gnome-themes-extra;
    iconTheme = "Tela-nord";
    iconThemePackage = pkgs.tela-icon-theme;
    uiFont = "Ubuntu Sans";
    uiFontSerif = "Noto Serif";
    uiFontSize = 10;
    uiFontBold = "Ubuntu Sans Bold";
    codeFont = "CaskaydiaMono Nerd Font Mono";
    codeFontSize = 14;
    terminalFont = "FiraMono Nerd Font Mono";
    terminalFontSize = 12;
    ghosttyTheme = "Everforest Dark Hard";
    uiAccentColor = "#d3c6aa";
    uiBaseColor = "#2d353b";
    fonts = with pkgs; [
      ubuntu-sans
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-mono
    ];
  };

  ayuMirage = {
    base16Scheme = "ayu-mirage";
    gtkTheme = "Adwaita-dark";
    gtkThemePackage = pkgs.gnome-themes-extra;
    iconTheme = "Tela-nord";
    iconThemePackage = pkgs.tela-icon-theme;
    uiFont = "Ubuntu Sans";
    uiFontSerif = "Noto Serif";
    uiFontSize = 10;
    uiFontBold = "Ubuntu Sans Bold";
    codeFont = "CaskaydiaMono Nerd Font Mono";
    codeFontSize = 14;
    terminalFont = "FiraMono Nerd Font Mono";
    terminalFontSize = 12;
    ghosttyTheme = "Everforest Dark Hard";
    fonts = with pkgs; [
      ubuntu-sans
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-mono
    ];
  };
}
