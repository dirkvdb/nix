{
  config,
  pkgs,
  ...
}:
let
  presets = import ../../theme/presets.nix { inherit pkgs; };
  cfg = config.local.theme;
  selectedPreset = presets.${cfg.preset} or presets.everforest;
in
{
  config.fonts.packages = selectedPreset.fonts or [ ];
}
