{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.spotify;
  scale = toString config.local.desktop.displayScale;
in
{
  options.local.apps.spotify = {
    enable = lib.mkEnableOption "Install Spotify desktop app";
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
  };
}
