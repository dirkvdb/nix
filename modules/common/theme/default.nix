{
  lib,
  config,
  pkgs,
  system,
  ...
}:

let
  presets = import ./presets.nix { inherit pkgs; };

  cfg = config.local.theme;
  isLinux = lib.hasInfix "linux" system;

  # Get the selected preset, or use everforest as default
  selectedPreset = presets.${cfg.preset} or presets.everforest;

in
{
  options.local.theme = {
    preset = lib.mkOption {
      type = lib.types.enum (builtins.attrNames presets);
      default = "everforest";
      description = "Theme preset to use";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.name;
      description = "Theme name";
    };

    base16Scheme = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          path
          lines
          attrs
        ];
      default = selectedPreset.base16Scheme;
      description = "Base16 color scheme";
    };

    uiAccentColor = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.uiAccentColor;
      description = "Base16 color scheme";
    };

    uiBaseColor = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.uiBaseColor;
      description = "Base16 color scheme";
    };

    gtkTheme = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.gtkTheme;
      description = "GTK theme name";
    };

    iconTheme = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.iconTheme;
      description = "Icon theme name";
    };

    gtkThemePackage = lib.mkOption {
      type = lib.types.package;
      default = selectedPreset.gtkThemePackage;
      description = "GTK theme package";
    };

    iconThemePackage = lib.mkOption {
      type = lib.types.package;
      default = selectedPreset.iconThemePackage;
      description = "Icon theme package";
    };

    uiFont = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.uiFont;
      description = "UI font family";
    };

    uiFontSize = lib.mkOption {
      type = lib.types.int;
      default = selectedPreset.uiFontSize;
      description = "UI font size";
    };

    uiFontBold = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.uiFontBold;
      description = "UI font family (bold variant)";
    };

    uiFontSerif = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.uiFontSerif;
      description = "UI font family (serif variant)";
    };

    codeFont = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.codeFont;
      description = "Code font family";
    };

    codeFontSize = lib.mkOption {
      type = lib.types.int;
      default = selectedPreset.codeFontSize;
      description = "Code font size";
    };

    terminalFont = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.terminalFont;
      description = "Terminal font family";
    };

    terminalFontSize = lib.mkOption {
      type = lib.types.int;
      default = selectedPreset.terminalFontSize;
      description = "Terminal font size";
    };

    ghosttyTheme = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.ghosttyTheme;
      description = "Ghostty terminal theme";
    };
  };

  config = {
    # Automatically install fonts required by the selected preset
    fonts.packages = selectedPreset.fonts or [ ];

    stylix = {
      polarity = "dark";
      image = ./wallpapers/wallpaper-1.jpg;
      base16Scheme = selectedPreset.base16Scheme;

      fonts = {
        sizes = {
          applications = selectedPreset.uiFontSize;
          desktop = selectedPreset.uiFontSize - 1;
          popups = selectedPreset.uiFontSize - 2;
          terminal = selectedPreset.terminalFontSize;
        };

        serif.name = selectedPreset.uiFontSerif;
        sansSerif.name = selectedPreset.uiFont;
        monospace.name = selectedPreset.terminalFont;
      };
    }
    // lib.optionalAttrs isLinux {
      icons = {
        enable = true;
        dark = selectedPreset.iconTheme;
        light = selectedPreset.iconTheme;
        package = selectedPreset.iconThemePackage;
      };

      cursor = {
        name = "macOS";
        size = 24;
        package = pkgs.apple-cursor;
      };
    };
  };
}
