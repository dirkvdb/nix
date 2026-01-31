{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.skhd;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.home-manager.skhd = {
    enable = lib.mkEnableOption "Hotkey manager";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    services.skhd = {
      enable = true;
      config = ''
        alt - return : ${pkgs.wezterm}/bin/wezterm
        alt - d : ${pkgs.zed-editor}/bin/zeditor
        alt - b : open -na zen
        alt - e : open ${user.homeDir}
      '';
    };
  });
}
