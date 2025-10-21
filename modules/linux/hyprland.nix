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

  environment.systemPackages = with pkgs; [
    walker
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
