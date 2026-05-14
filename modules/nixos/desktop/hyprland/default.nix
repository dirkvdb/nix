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

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
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
      mesa
      nwg-displays
      satty # screenshot annotation tool
      slurp # for region selection (screen shot, etc)
      wf-recorder # screen recording for Wayland
      sunsetr
      hyprsunset
      waypaper
      wayfreeze # for screenshots
      hyprland-qt-support
      wl-clipboard
    ];
  };
}
