{
  lib,
  config,
  pkgs,
  mkHome,
  inputs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.fastpotify;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
  settingsFile = pkgs.writeText "fastpotify-settings.json" ''
    {
      "device_name": ${builtins.toJSON config.local.system.network.hostname},
      "bitrate": 320,
      "normalisation": false,
      "autoplay": true,
      "gapless": true,
      "audio_backend": null,
      "audio_device": null,
      "audio_buffer_ms": 100,
      "audio_cache": true,
      "audio_cache_mb": 1024,
      "theme": "system",
      "accent_from_art": true,
      "volume": 45874,
      "sidebar_visible": true,
      "art_expanded": false,
      "sidebar_compact": false,
      "sidebar_width": 250.0,
      "lyrics_width": 360.0,
      "queue_width": 360.0,
      "tracklist_compact": false,
      "search_history": [],
      "show_shortcut_hints": true,
      "web_client_id": null,
      "playback_authorized": true,
      "keep_playing_in_background": true,
      "check_for_updates": false,
      "pinned_contexts": [],
      "sidebar_order": [],
      "zoom": 1.0,
      "winamp_window": false,
      "skin": null,
      "skin_scale": 3,
      "winamp_on_top": false,
      "vis": "bars",
      "playlist_open": false,
      "playlist_height": 174,
      "eq_open": false,
      "eq_on": false,
      "eq_preamp_db": 0.0,
      "eq_bands_db": [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
      ],
      "balance": 0.0,
      "mono": false,
      "playlist_shaded": false,
      "eq_shaded": false,
      "winamp_shaded": false,
      "milkdrop_open": false,
      "milkdrop_seconds": 10,
      "milkdrop_fps": 60,
      "milkdrop_screen_hz": 0,
      "milkdrop_scale": 1,
      "milkdrop_fullscreen": false,
      "milkdrop_size": [
        640.0,
        480.0
      ]
    }
  '';
in
{
  options.local.apps.fastpotify = {
    enable = lib.mkEnableOption "Fastpotify Spotify client";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    home.packages = [ pkgs.fastpotify ];

    # Render the SOPS-managed client ID at activation time so it never enters
    # the Nix store. Keep the result writable because Fastpotify updates it.
    home.activation.fastpotifySettings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/fastpotify"
      ${pkgs.jq}/bin/jq \
        --arg web_client_id "$(cat ${config.sops.secrets.fastpotify_web_client_id.path})" \
        '.web_client_id = $web_client_id' \
        ${settingsFile} > "$HOME/.config/fastpotify/settings.json.tmp"
      chmod 600 "$HOME/.config/fastpotify/settings.json.tmp"
      mv -f "$HOME/.config/fastpotify/settings.json.tmp" "$HOME/.config/fastpotify/settings.json"
    '';
  });
}
