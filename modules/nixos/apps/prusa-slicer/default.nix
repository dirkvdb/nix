{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.prusa-slicer;
  user = config.local.user;

  # GStreamer plugins required by WebKit2GTK (used for OAuth login WebView).
  # Without gst-plugins-base the "appsink" element is missing, which causes
  # WebKit2GTK to log errors and can prevent the OAuth page from loading.
  gstPluginPath = pkgs.lib.makeSearchPath "lib/gstreamer-1.0" (
    with pkgs.gst_all_1;
    [
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
    ]
  );

  # Patch PrusaSlicer to call store.Delete(service) before store.Save() so that
  # a single canonical entry always exists in the secret store. Without this,
  # every OAuth login creates a new KeePassXC entry (the "user" attribute is the
  # shared_session_key which changes each session), and Load() may return a stale
  # empty-token entry on the next launch, forcing re-login every time.
  prusaSlicerPatched = pkgs.prusa-slicer.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./dedup-secret-store.patch ];
  });

  prusaSlicerWrapped = pkgs.symlinkJoin {
    name = "prusa-slicer-wrapped";
    paths = [ prusaSlicerPatched ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/prusa-slicer \
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"

      # Patch the desktop file to register the prusaslicer:// URL scheme handler.
      # The upstream file uses %F (file paths only); switch to %u so xdg-open
      # passes the full prusaslicer://open?file=... URL to the binary.
      rm $out/share/applications/PrusaSlicer.desktop
      sed \
        -e 's|^MimeType=|MimeType=x-scheme-handler/prusaslicer;|' \
        -e 's|^Exec=prusa-slicer %F|Exec=prusa-slicer %u|' \
        ${prusaSlicerPatched}/share/applications/PrusaSlicer.desktop \
        > $out/share/applications/PrusaSlicer.desktop
    '';
  };
in
{
  options.local.apps.prusa-slicer = {
    enable = lib.mkEnableOption "prusa-slicer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ prusaSlicerWrapped ];

    # Register prusaslicer:// URL scheme handler in home-manager
    home-manager.users.${user.name} = {
      xdg.mimeApps.associations.added = {
        "x-scheme-handler/prusaslicer" = "PrusaSlicer.desktop";
      };
      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/prusaslicer" = "PrusaSlicer.desktop";
      };
    };
  };
}
