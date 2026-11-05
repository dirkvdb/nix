{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  mkUserHome = mkHome user.name;
  themeFamily = builtins.fromJSON (builtins.readFile ../../../configs/themes/charcoal-grove.json);
  charcoalGrove = lib.findFirst (
    variant: variant.appearance == "dark"
  ) (throw "omarchy: Charcoal Grove dark palette is missing") themeFamily.themes;
  omarchyColors = (pkgs.formats.toml { }).generate "charcoal-grove-colors.toml" (
    import ../../../configs/themes/zed-to-omarchy.nix charcoalGrove
  );
in
{
  config = lib.mkMerge [
    (mkUserHome {
      xdg.dataFile."theme" = {
        source = ./${theme.name};
        recursive = true;
      };
    })
    (lib.mkIf (pkgs.stdenv.isLinux && (config.local.desktop.enable or false)) (mkUserHome {
      # Upstream consumers hard-code this path rather than honoring XDG_STATE_HOME.
      home.file.".local/state/omarchy/current/theme/colors.toml".source = omarchyColors;
      home.file.".local/state/omarchy/current/theme.name".text = "charcoal-grove\n";
    }))
  ];
}
