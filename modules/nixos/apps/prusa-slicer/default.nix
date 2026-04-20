{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.prusa-slicer;

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

  prusaSlicerWrapped = pkgs.symlinkJoin {
    name = "prusa-slicer-wrapped";
    paths = [ pkgs.prusa-slicer ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/prusa-slicer \
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"
    '';
  };
in
{
  options.local.apps.prusa-slicer = {
    enable = lib.mkEnableOption "prusa-slicer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ prusaSlicerWrapped ];
  };
}
