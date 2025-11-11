{ pkgs }:
{
  everforest = {
    name = "everforest";
    gtkTheme = "Adwaita-dark";
    gtkThemePackage = pkgs.gnome-themes-extra;
    iconTheme = "Tela nord";
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

  # Add more presets here
  # Example:
  # catppuccin = {
  #   name = "catppuccin";
  #   gtkTheme = "Catppuccin-Mocha";
  #   gtkThemePackage = pkgs.catppuccin-gtk;
  #   iconTheme = "Papirus-Dark";
  #   iconThemePackage = pkgs.papirus-icon-theme;
  #   uiFont = "Inter";
  #   uiFontSize = 11;
  #   uiFontBold = "Inter Bold";
  #   uiFontSerif = "Noto Serif";
  #   codeFont = "JetBrainsMono Nerd Font";
  codeFontSize = 14;
  #   terminalFont = "JetBrainsMono Nerd Font";
  #   terminalFontSize = 14;
  #   ghosttyTheme = "catppuccin-mocha";
  #   fonts = with pkgs; [
  #     inter
  #     nerd-fonts.jetbrains-mono
  #   ];
  # };
}
