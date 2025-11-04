{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop.hyprland;
in
{
  options.local.desktop.hyprland = {
    enable = lib.mkEnableOption "Enable hyprland desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # copy the font that contains the menu symbol used in the waybar config
    fonts.packages = [
      (pkgs.stdenvNoCC.mkDerivation {
        name = "omarchy";
        src = ./fonts;
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          cp omarchy.ttf $out/share/fonts/truetype/
        '';
      })
    ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = false;
      withUWSM = false;
    };



    # Hyprland-specific packages
    environment.systemPackages = with pkgs; [
      grim # grab images from a Wayland compositor
      hyprpolkitagent
      pyprland
      hyprlang
      hyprpicker
      hyprshot
      hyprcursor
      mako
      mesa
      nwg-displays
      nwg-look
      satty # screenshot annotation tool
      slurp # for region selection (screen shot, etc)
      sunsetr
      swayosd
      hyprsunset
      waypaper
      wayfreeze # for screenshots
      hyprland-qt-support
      wl-clipboard
    ];
  };
}
