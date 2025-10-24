{
  config,
  pkgs,
  ...
}:
{
  fonts.packages = [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "omarchy";
      src = ../../fonts;
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp omarchy.ttf $out/share/fonts/truetype/
      '';
    })
  ];

  programs.uwsm = {
    enable = true;
    waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/Hyprland";
    };
  };

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
  environment.sessionVariables.TERMINAL = "wezterm";
  environment.sessionVariables.EDITOR = "micro";

  # Hyprland-specific packages
  environment.systemPackages = with pkgs; [
    hypridle
    hyprpolkitagent
    pyprland
    gawk
    hyprlang
    hyprshot
    hyprcursor
    mesa
    nwg-displays
    nwg-look
    waypaper
    hyprland-qt-support
  ];
}
