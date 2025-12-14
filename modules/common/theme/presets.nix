{ pkgs }:
{
  # everforest color scheme2
  # base00: "#2d353b" # bg0,       palette1 dark
  # base01: "#343f44" # bg1,       palette1 dark
  # base02: "#475258" # bg3,       palette1 dark
  # base03: "#859289" # grey1,     palette2 dark
  # base04: "#9da9a0" # grey2,     palette2 dark
  # base05: "#d3c6aa" # fg,        palette2 dark
  # base06: "#e6e2cc" # bg3,       palette1 light
  # base07: "#fdf6e3" # bg0,       palette1 light
  # base08: "#e67e80" # red,       palette2 dark
  # base09: "#e69875" # orange,    palette2 dark
  # base0A: "#dbbc7f" # yellow,    palette2 dark
  # base0B: "#a7c080" # green,     palette2 dark
  # base0C: "#83c092" # aqua,      palette2 dark
  # base0D: "#7fbbb3" # blue,      palette2 dark
  # base0E: "#d699b6" # purple,    palette2 dark
  # base0F: "#9da9a0" # grey2,     palette2 dark

  everforest = {
    name = "everforest";
    base16Scheme = {
      base00 = "2d353b";
      base01 = "343f44";
      base02 = "475258";
      base03 = "859289";
      base04 = "9da9a0";
      base05 = "d3c6aa";
      base06 = "e6e2cc";
      base07 = "fdf6e3";
      base08 = "e67e80";
      base09 = "e69875";
      base0A = "dbbc7f";
      base0B = "a7c080";
      base0C = "83c092";
      base0D = "d3c6aa"; # mod use ui accesnt color
      base0E = "7fbbb3"; # mod use blue for purple
      base0F = "9da9a0";
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
    uiAccentColor = "#d3c6aa";
    uiBaseColor = "#2d353b";
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
