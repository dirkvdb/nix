{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.helix;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.helix = {
    enable = lib.mkEnableOption "helix ide";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.helix = {
      enable = true;
      settings = {
        editor.cursor-shape = {
          insert = "bar";
        };
      };
    };
  });
}
