{ pkgs }:
{
  # Earthbound Slate: neutral charcoal UI surfaces with earthy broken-white
  # foregrounds. base08-0F are semantic colors and must not be used for
  # ordinary UI controls, selections, borders, or hover states.

  everforest = {
    name = "everforest";
    base16Scheme = {
      base00 = "272a2f";
      base01 = "2d3035";
      base02 = "3a3d42";
      base03 = "67645f";
      base04 = "948b7e";
      base05 = "dec39d";
      base06 = "ebcfaa";
      base07 = "f4dab7";
      base08 = "d0847f";
      base09 = "c99774";
      base0A = "d1b477";
      base0B = "9eaa82";
      base0C = "82a6a0";
      # Stylix commonly maps base0D to generic UI accents, so keep it neutral.
      base0D = "dec39d";
      base0E = "b29aaa";
      base0F = "a8796b";
    };
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
    uiAccentColor = "#dec39d";
    uiBaseColor = "#272a2f";
    fonts = with pkgs; [
      ubuntu-sans
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-mono
    ];
  };

  ayuMirage = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-mirage.yaml";
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
    terminalFontSize = 13;
    ghosttyTheme = "Everforest Dark Hard";
    fonts = with pkgs; [
      ubuntu-sans
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-mono
    ];
  };
}
