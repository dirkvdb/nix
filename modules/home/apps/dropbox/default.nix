{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.home-manager.dropbox;
in
{
  options.local.home-manager.dropbox = {
    enable = lib.mkEnableOption "Dropbox file sync";

    path = lib.mkOption {
      type = lib.types.str;
      description = "Location of the Dropbox folder.";
      example = "${config.home.homeDirectory}/Dropbox";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} =  {
      services.dropbox = {
        enable = true;
        path = cfg.path or "${config.home.homeDirectory}/Dropbox";
      };
    };
  };
}
