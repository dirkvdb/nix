{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  cairo,
  dbus,
  gdk-pixbuf,
  glib,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
  gst_all_1,
  libayatana-appindicator,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "decentpaste";
  version = "0.8.1";

  src =
    let
      srcs = {
        x86_64-linux = fetchurl {
          url = "https://github.com/decentpaste/decentpaste/releases/download/v${finalAttrs.version}/DecentPaste_${finalAttrs.version}_amd64.deb";
          hash = "sha256-UXnYcx5P+oX7B/TgPC4/sSCtTscdYv5g/hzUnls9CoU=";
        };
        aarch64-linux = fetchurl {
          url = "https://github.com/decentpaste/decentpaste/releases/download/v${finalAttrs.version}/DecentPaste_${finalAttrs.version}_arm64.deb";
          hash = "sha256-JQYT2gqd5AfIq/0mEpJ4Isr4F97/akwr9s2rl3qM7lE=";
        };
      };
    in
    srcs.${stdenv.hostPlatform.system}
      or (throw "decentpaste: unsupported system ${stdenv.hostPlatform.system}");

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    cairo
    dbus
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libsoup_3
    webkitgtk_4_1
  ];

  dontBuild = true;
  dontConfigure = true;
  dontStrip = true;

  unpackPhase = ''
    ar x $src
    tar xzf data.tar.gz
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/decentpaste-app "$out/bin/.decentpaste-app-unwrapped"

    makeWrapper "$out/bin/.decentpaste-app-unwrapped" "$out/bin/decentpaste-app" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libayatana-appindicator ]}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gstreamer.out}/lib/gstreamer-1.0" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0"

    install -Dm644 usr/share/applications/DecentPaste.desktop \
      "$out/share/applications/DecentPaste.desktop"

    for size in 32x32 128x128 "256x256@2"; do
      icon="usr/share/icons/hicolor/$size/apps/decentpaste-app.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" "$out/share/icons/hicolor/$size/apps/decentpaste-app.png"
      fi
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Universal clipboard for every device — cross-platform P2P clipboard sharing";
    longDescription = ''
      DecentPaste lets you seamlessly share your clipboard between all your
      devices over your local network. Copy on your laptop, paste on your phone.
      No cloud servers, no accounts, no subscriptions — just secure,
      peer-to-peer clipboard sync with end-to-end AES-256-GCM encryption.
    '';
    homepage = "https://github.com/decentpaste/decentpaste";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "decentpaste-app";
  };
})
