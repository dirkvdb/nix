{
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.dropbox;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.dropbox = {
    enable = lib.mkEnableOption "Dropbox file sync";

    path = lib.mkOption {
      type = lib.types.str;
      description = "Location of the Dropbox folder.";
      example = "${config.home.homeDirectory}/Dropbox";
    };
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    services.dropbox = {
      enable = true;
      path = cfg.path or "${config.home.homeDirectory}/Dropbox";
    };
  });
}
