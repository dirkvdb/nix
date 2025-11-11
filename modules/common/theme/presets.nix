{ pkgs }:
{
  everforest = {
    name = "everforest";
    gtkTheme = "Adwaita-dark";
    gtkThemePackage = pkgs.gnome-themes-extra;
    iconTheme = "Tela nord";
    iconThemePackage = pkgs.tela-icon-theme;
    uiFont = "Ubuntu Sans";
    uiFontSize = 10;
    uiFontBold = "Ubuntu Sans Bold";
    codeFont = "CaskaydiaMono Nerd Font Mono";
    terminalFont = "FiraMono Nerd Font Mono";
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
  #   codeFont = "JetBrainsMono Nerd Font";
  #   terminalFont = "JetBrainsMono Nerd Font";
  #   fonts = with pkgs; [
  #     inter
  #     nerd-fonts.jetbrains-mono
  #   ];
  # };
}
