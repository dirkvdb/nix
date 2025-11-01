{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.karabiner;
in
{
  options.local.apps.karabiner = {
    enable = lib.mkEnableOption "Install Karabiner keryboard customizer";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      xdg.configFile."karabiner".source = ./karabiner;

      home.packages = with pkgs; [
        karabiner-elements
      ];
    };
  };
}
