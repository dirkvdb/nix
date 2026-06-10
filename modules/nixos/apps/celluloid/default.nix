{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.celluloid;
  user = config.local.user;
in
{
  options.local.apps.celluloid = {
    enable = lib.mkEnableOption "celluloid";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/x-msvideo"
        "video/quicktime"
        "video/mpeg"
        "video/x-flv"
        "video/ogg"
        "audio/mpeg"
        "audio/flac"
        "audio/ogg"
        "audio/x-wav"
        "audio/mp4"
      ];
      description = "MIME types for which Celluloid is the default handler.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.celluloid.override { youtubeSupport = false; })
    ];

    home-manager.users.${user.name} = {
      xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (
        _: "io.github.celluloid_player.Celluloid.desktop"
      );
    };
  };
}
