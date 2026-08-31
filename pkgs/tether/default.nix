{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  gettext,
  avahi,
  bluez,
  gtk3,
  gtk-layer-shell,
  gtest,
  hicolor-icon-theme,
  libnotify,
  nlohmann_json,
  openssl,
  wayland,
  wrapGAppsHook3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tether";
  version = "0.2.19";

  src = fetchFromGitHub {
    owner = "zackb";
    repo = "tether";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3184+dHzgqh+QrdaCCBtQEzNmoJq03rl6wf0FTK1TTc=";
  };

  postPatch = ''
    sed -i '/^include(FetchContent)$/,/^set(CMAKE_WARN_DEPRECATED ON CACHE BOOL "" FORCE)$/d' CMakeLists.txt
    sed -i '/^find_package(PkgConfig REQUIRED)$/a find_package(GTest REQUIRED)\nfind_package(nlohmann_json REQUIRED)' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
    gettext
    hicolor-icon-theme
    ninja
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    avahi
    bluez
    gtest
    gtk3
    gtk-layer-shell
    libnotify
    nlohmann_json
    openssl
    wayland
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DTETHER_BUILD_EXTENSIONS=OFF"
    "-DBLUETOOTHD_PATH=${bluez}/libexec/bluetooth/bluetoothd"
    "-DCHROME_MESSAGING_DIR=${placeholder "out"}/share/chromium/native-messaging-hosts"
    "-DGOOGLE_CHROME_MESSAGING_DIR=${placeholder "out"}/share/opt/chrome/native-messaging-hosts"
  ];

  meta = {
    description = "Bridge an iPhone to the Linux desktop with Continuity features";
    homepage = "https://github.com/zackb/tether";
    license = lib.licenses.mit;
    mainProgram = "tether";
    platforms = lib.platforms.linux;
  };
})
