{
  config,
  pkgs,
  ...
}:
{
  programs.uwsm.enable = true;
  programs.hyprlock.enable = true;
  programs.waybar.enable = true;
  #programs.hypridle.enable = true;
  #programs.hyprsunset.enable = true;
  #programs.hyprpicker.enable = true;

  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Enable XDG portal for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
