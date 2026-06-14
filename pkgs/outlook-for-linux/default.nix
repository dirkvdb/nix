{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cargo-tauri,
  nodejs,
  npmHooks,
  fetchNpmDeps,
  pkg-config,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  libayatana-appindicator,
  libsoup_3,
  openssl,
  glib-networking,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "outlook-for-linux";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "maxiking445";
    repo = "outlook-for-linux";
    rev = "v${finalAttrs.version}";
    hash = "sha256-M0pKeyzZSoGysM4yzc/sqKz+g0QEROycPjuND85aoAc=";
  };

  npmDeps = fetchNpmDeps {
    src = "${finalAttrs.src}/client";
    hash = "sha256-uq6V5KBbrtj098o2Yt0yzLxqkb7EhQrismxu2oQfyXI=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    src = "${finalAttrs.src}/client/src-tauri";
    hash = "sha256-UL3WtJdFi/djGlrJ+mCMxaGe9WxmgUaaxM+p2a1tOCw=";
  };

  sourceRoot = "${finalAttrs.src.name}/client";

  patches = [
    ./open-http-links-in-browser.patch
    ./persist-session-cookies.patch
  ];

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo-tauri.hook
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libayatana-appindicator
    libsoup_3
    openssl
    glib-networking
  ];

  cargoRoot = "src-tauri";

  tauriBuildFlags = [ "--no-bundle" ];

  postPatch = ''
    substituteInPlace src-tauri/tauri.conf.json \
      --replace-fail '"beforeBuildCommand": "npm run build"' '"beforeBuildCommand": ""' \
      --replace-fail '"productName": "Outlook for Linux"' '"productName": "outlook-for-linux"' \
      --replace-fail '"fullscreen": false' '"fullscreen": false, "decorations": false'
  '';

  preBuild = ''
    npm run build
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]})
  '';

  dontTauriInstall = true;

  installPhase =
    let
      desktopEntry = ''
        [Desktop Entry]
        Version=1.0
        Name=Outlook for Linux
        Comment=An unofficial Linux desktop wrapper for Microsoft Outlook
        Exec=outlook-for-linux
        Terminal=false
        Type=Application
        Icon=outlook-for-linux
        Categories=Network;Email;
        StartupNotify=true
        StartupWMClass=outlook-for-linux
      '';
    in
    ''
      runHook preInstall
      install -Dm755 src-tauri/target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/OutlookClient $out/bin/outlook-for-linux
      install -Dm644 src-tauri/icons/128x128.png $out/share/icons/hicolor/128x128/apps/outlook-for-linux.png
      install -Dm644 src-tauri/icons/32x32.png $out/share/icons/hicolor/32x32/apps/outlook-for-linux.png
      install -Dm644 <(echo ${lib.escapeShellArg desktopEntry}) $out/share/applications/outlook-for-linux.desktop
      runHook postInstall
    '';

  meta = {
    description = "An unofficial Linux desktop wrapper for Microsoft Outlook built with Tauri";
    homepage = "https://github.com/maxiking445/outlook-for-linux";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    mainProgram = "outlook-for-linux";
    platforms = lib.platforms.linux;
  };
})
