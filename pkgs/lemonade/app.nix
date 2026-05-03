{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  rustPlatform,
  makeWrapper,
  wrapGAppsHook3,
  pkg-config,
  # Linux Tauri v2 system dependencies
  webkitgtk_4_1,
  libsoup_3,
  gtk3,
  glib,
  gdk-pixbuf,
  pango,
  cairo,
  atk,
  openssl,
  wayland,
  xorg,
  libayatana-appindicator,
  gst_all_1,
}:
let
  versionInfo = import ./version.nix;
  pname = "lemonade-app";
  version = versionInfo.version;

  src = fetchFromGitHub {
    owner = versionInfo.src.owner;
    repo = versionInfo.src.repo;
    rev = "v${version}";
    hash = versionInfo.src.hash;
  };

  # Build the webpack renderer bundle (TypeScript/React → static HTML/JS/CSS).
  # webpack.config.js outputs to dist/renderer/ relative to src/app/.
  renderer = buildNpmPackage {
    pname = "${pname}-renderer";
    inherit version src;
    sourceRoot = "source/src/app";

    npmDepsHash = "sha256-EdmbKKIOdlzzZiZnIAhu5oqrQUmVFkoAQ/7OCUypL8Q=";

    npmFlags = [ "--ignore-scripts" ];

    buildPhase = ''
      runHook preBuild
      npm run build:renderer:prod
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # Copy the built renderer assets to $out
      mkdir -p "$out"
      cp -r dist/renderer/. "$out/"
      runHook postInstall
    '';

    dontStrip = true;
  };
in
rustPlatform.buildRustPackage {
  inherit pname version src;

  # Cargo.toml lives in src/app/src-tauri/
  sourceRoot = "source/src/app/src-tauri";

  # All dependencies are from crates.io, so no outputHashes needed.
  cargoLock = {
    lockFile = src + "/src/app/src-tauri/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    webkitgtk_4_1 # webkit2gtk-4.1, javascriptcore-4.1
    libsoup_3 # soup-3.0 (used by webkit2gtk internally)
    gtk3 # gtk+-3.0, gdk-3.0, gdk-wayland-3.0
    glib # glib-2.0, gio-2.0, gobject-2.0
    gdk-pixbuf # gdk-pixbuf-2.0
    pango # pango, pangocairo
    cairo # cairo
    atk # atk
    openssl # TLS for reqwest
    wayland # wayland-client (for gdkwayland)
    xorg.libX11 # x11 (for gdkx11)
    libayatana-appindicator # system tray support (runtime)
    gst_all_1.gstreamer # GStreamer core (needed by WebKitGTK for media)
    gst_all_1.gst-plugins-base # appsink, playback, audio/video converters
    gst_all_1.gst-plugins-good # common codecs, matroska, rtp, etc.
    gst_all_1.gst-plugins-bad # additional codecs used by WebRTC/media
  ];

  # The tauri.conf.json has beforeBuildCommand = "npm run build:renderer:prod"
  # and frontendDist = "../dist/renderer" (relative to src-tauri/).
  # We pre-build the renderer as a separate derivation and:
  # 1. Remove the before-build command so cargo doesn't try to run npm
  # 2. Point frontendDist directly to the renderer's Nix store path,
  #    which is a declared build input and thus accessible in the sandbox.
  #    tauri-build (build.rs) reads the assets from this path and embeds
  #    them directly into the Rust binary at compile time.
  # 3. Enable the `custom-protocol` Cargo feature.  `cargo tauri build` does
  #    this automatically, but since we call `cargo build --release` directly,
  #    we must add it ourselves.  Without it Tauri's build.rs sets
  #    `dev = true` and the runtime loads from devUrl (localhost:9123) instead
  #    of using the embedded frontend assets.
  # 4. Remove the backgroundColor field. On Linux + Wayland, setting
  #    backgroundColor causes tao/wry to request a GDK RGBA visual
  #    (gdk_screen_get_rgba_visual + gtk_widget_set_app_paintable), which
  #    breaks WebKitGTK compositing — the webview renders to a buffer that
  #    never gets composited into the GTK window surface, resulting in a
  #    completely black window.
  postPatch = ''
    substituteInPlace tauri.conf.json \
      --replace-fail '"beforeBuildCommand": "npm run build:renderer:prod"' '"beforeBuildCommand": ""' \
      --replace-fail '"frontendDist": "../dist/renderer"' '"frontendDist": "${renderer}"'

    # Enable custom-protocol feature so Tauri embeds and serves the frontend
    # assets instead of trying to connect to devUrl.
    substituteInPlace Cargo.toml \
      --replace-fail 'features = ["protocol-asset", "image-ico"]' \
                     'features = ["protocol-asset", "image-ico", "custom-protocol"]'

    # Remove the backgroundColor field to prevent tao/wry from requesting an
    # RGBA visual, which breaks WebKitGTK compositing on Wayland.
    sed -i '/"backgroundColor"/d' tauri.conf.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    # With --target set (e.g. x86_64-unknown-linux-gnu), cargo puts the binary
    # in target/<triple>/release/ not target/release/. Use find to locate it.
    local binary
    binary=$(find target -name "lemonade-app" -not -path "*/deps/*" -type f 2>/dev/null | head -n1)
    if [ -z "$binary" ]; then
      echo "ERROR: lemonade-app binary not found in target/"
      exit 1
    fi
    install -Dm755 "$binary" "$out/bin/lemonade-app"

    # Install desktop entry (located at repo-root/data/ = ../../../data/ from src-tauri/)
    if [ -f "../../../data/lemonade-app.desktop" ]; then
      mkdir -p "$out/share/applications"
      cp "../../../data/lemonade-app.desktop" "$out/share/applications/"
      substituteInPlace "$out/share/applications/lemonade-app.desktop" \
        --replace-fail "Exec=lemonade-app" "Exec=$out/bin/lemonade-app" \
        --replace-fail "Name=Lemonade App" "Name=Lemonade"
    fi

    # Install icon from the Tauri icons directory
    if [ -f "icons/128x128.png" ]; then
      mkdir -p "$out/share/icons/hicolor/128x128/apps"
      cp "icons/128x128.png" "$out/share/icons/hicolor/128x128/apps/lemonade-app.png"
    fi

    runHook postInstall
  '';

  # Point GStreamer at the plugin directories so WebKitGTK can find appsink,
  # playback bins, codecs, etc.  wrapGAppsHook3 does not handle this.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0"
    )
  '';

  # Tauri binaries embed the frontend; no need to strip debug symbols separately.
  dontStrip = true;

  meta = {
    description = "Lemonade LLM GUI application (Tauri)";
    homepage = "https://github.com/${versionInfo.src.owner}/${versionInfo.src.repo}";
    license = lib.licenses.mit;
    # Tauri v2 on Linux uses GTK3 + webkit2gtk-4.1
    platforms = lib.platforms.linux;
    mainProgram = "lemonade-app";
  };
}
