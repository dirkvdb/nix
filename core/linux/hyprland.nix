{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.nixCfg.hyprland;
in
{
  # hyprland.enable option moved to core/default.nix

  config = lib.mkIf cfg.enable {
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

    #programs.hyprsunset.enable = true;
    #programs.hyprpicker.enable = true;

    programs.hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      withUWSM = true;
    };

    # Enable polkit for privilege escalation
    security.polkit.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    environment.sessionVariables.TERMINAL = "ghostty";
    environment.sessionVariables.EDITOR = "micro";

    # Hyprland-specific packages
    environment.systemPackages = with pkgs; [
      hyprpolkitagent
      pyprland
      hyprlang
      hyprshot
      hyprcursor
      mesa
      nwg-displays
      nwg-look
      waypaper
      hyprland-qt-support
    ];
  };
}
