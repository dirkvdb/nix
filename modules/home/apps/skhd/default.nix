{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.skhd;
in
{
  options.local.home-manager.skhd = {
    enable = lib.mkEnableOption "Hotkey manager";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.skhd = {
        enable = true;
        config = ''
          alt - return : ${pkgs.wezterm}/bin/wezterm
          alt - d : ${pkgs.zed-editor}/bin/zeditor
          alt - b : open -na zen
          alt - e : open ${user.homeDir}
        '';
      };
    };
  };
}
