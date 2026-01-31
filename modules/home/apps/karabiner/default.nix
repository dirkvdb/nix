{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.karabiner;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.karabiner = {
    enable = lib.mkEnableOption "Install Karabiner keryboard customizer";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    xdg.configFile."karabiner".source = ./karabiner;

    home.packages = with pkgs; [
      karabiner-elements
    ];
  });
}
