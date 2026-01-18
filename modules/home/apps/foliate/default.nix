{
  lib,
  config,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.foliate;
in
{
  options.local.apps.foliate = {
    enable = lib.mkEnableOption "Ebook reader";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.foliate = {
        enable = true;

        settings = {
          "viewer/view" = {
            animated = false;
            autohide-cursor = true;
            max-column-count = 1;
          };
          "viewer/font" = {
            minimum-size = 14;
          };
        };
      };
    };
  };
}
