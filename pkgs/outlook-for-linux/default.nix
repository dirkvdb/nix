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
  version = "0.1.12-unstable-2026-06-03";

  src = fetchFromGitHub {
    owner = "maxiking445";
    repo = "outlook-for-linux";
    rev = "2d94dbc45a44dffd9ceca00081172a9e8837a034";
    hash = "sha256-Jdw84Lb9MwjC1jPwlii//G8l0k9zJSNAHELkcGHOoAk=";
  };

  npmDeps = fetchNpmDeps {
    src = "${finalAttrs.src}/client";
    hash = "sha256-FY3GSKzLD165deV2FcsRikP8mwXK9I7jb47T2HE/YJk=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    src = "${finalAttrs.src}/client/src-tauri";
    hash = "sha256-oJNx6mprc7niOydP3ohvlbiyusGMl847GibIzv/UL0Q=";
  };

  sourceRoot = "${finalAttrs.src.name}/client";

  patches = [
    ./open-http-links-in-browser.patch
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
      install -Dm755 src-tauri/target/x86_64-unknown-linux-gnu/release/OutlookClient $out/bin/outlook-for-linux
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
