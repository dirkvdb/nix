{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.spotify;
  user = config.local.user;
  scale = toString config.local.desktop.displayScale;
in
{
  options.local.apps.spotify = {
    enable = lib.mkEnableOption "Install Spotify desktop app";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "x-scheme-handler/spotify"
      ];
      description = "MIME types for which Spotify is the default handler.";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.spotify.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/spotify \
            --add-flags "--force-device-scale-factor=${scale}"
        '';
      }))
    ];

    home-manager.users.${user.name} = {
      xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "spotify.desktop");
    };
  };
}
