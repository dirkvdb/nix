{
  config,
  lib,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;
  cfg = config.local.desktop.waybar;
  mkUserHome = mkHome user.name;

  # Directory holding all theme wallpapers. wpaperd will pick & rotate them.
  wallpapersDir = ../../../common/theme/wallpapers;
in
{
  config = lib.mkIf (isDesktop && !isHeadless && isHyprlandEnabled && cfg.enable) (mkUserHome {
    stylix.targets.wpaperd.image.enable = false;

    # Use wpaperd to display and rotate wallpapers natively. It cycles through
    # all images in the configured directory based on `duration` and `sorting`,
    # so no custom systemd timer is required.
    services.wpaperd = {
      enable = true;
      package = unstablePkgs.wpaperd;
      settings = {
        any = {
          path = "${wallpapersDir}";
          duration = "30m";
          sorting = "random";
          mode = "center";
        };
      };
    };
  });
}
