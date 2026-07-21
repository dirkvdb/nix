{
  pkgs,
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  inherit (config.lib.stylix) colors;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf (isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
    xdg.configFile."hyprexpose/config.toml".text = ''
      [appearance]
      font = "${theme.uiFont} 11"
      label_font = "${theme.uiFont} Bold 13"
      card_padding = 24.0
      card_radius = 12.0
      max_card_width = 480.0
      max_card_height = 320.0
      label_height = 32.0
      thumb_padding = 4.0
      select_border = 2.0

      [colors]
      background = "#${colors.base00}bf"
      card = "#${colors.base01}f2"
      selection = "${theme.uiAccentColor}e6"
      label = "#${colors.base05}ff"
      empty_label = "#${colors.base04}94"
      window_label = "#${colors.base06}e6"
      active_window = "${theme.uiAccentColor}f2"

      [behavior]
      no_preview = false
      switch_on_move = true
      allow_mouse = true
    '';

    wayland.windowManager.hyprland.settings = {
      on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("${pkgs.hyprexpose}/bin/hyprexpose")
              end'')
          ];
        }
      ];
    };
  });
}
