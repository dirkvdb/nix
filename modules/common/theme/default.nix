{ lib, ... }:
{
  options.local.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "everforest";
      description = "Theme name";
    };

    gtkTheme = lib.mkOption {
      type = lib.types.str;
      default = "Adwaita-dark";
      description = "GTK theme name";
    };

    iconTheme = lib.mkOption {
      type = lib.types.str;
      default = "Tela nord";
      description = "Icon theme name";
    };

    uiFont = lib.mkOption {
      type = lib.types.str;
      default = "Ubuntu Sans";
      description = "UI font family";
    };

    uiFontSize = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "UI font sizee";
    };

    uiFontBold = lib.mkOption {
      type = lib.types.str;
      default = "Ubuntu Sans Bold";
      description = "UI font family (bold variant)";
    };

    codeFont = lib.mkOption {
      type = lib.types.str;
      default = "CaskaydiaMono Nerd Font Mono";
      description = "Code font family";
    };

    terminalFont = lib.mkOption {
      type = lib.types.str;
      default = "FiraMono Nerd Font Mono";
      description = "Terminal font family";
    };
  };

}
