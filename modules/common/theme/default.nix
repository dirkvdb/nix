{
  lib,
  config,
  pkgs,
  ...
}:

let
  presets = import ./presets.nix { inherit pkgs; };

  cfg = config.local.theme;

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

    codeFont = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.codeFont;
      description = "Code font family";
    };

    terminalFont = lib.mkOption {
      type = lib.types.str;
      default = selectedPreset.terminalFont;
      description = "Terminal font family";
    };
  };

  config = {
    # Automatically install fonts required by the selected preset
    fonts.packages = selectedPreset.fonts or [ ];
  };
}
