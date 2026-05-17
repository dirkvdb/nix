{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  gettext,
  ffmpeg,
  freetype,
  harfbuzz,
  icu,
  libgit2,
  curl,
  pugixml,
  SDL2,
  alsa-lib,
  bluez,
  libGL,
  lunasvg,
  poppler,
  rlottie,
  freeimage,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "es-de";
  version = "3.4.1";

  src = fetchurl {
    url = "https://gitlab.com/es-de/emulationstation-de/-/archive/v${finalAttrs.version}/emulationstation-de-v${finalAttrs.version}.tar.bz2";
    hash = "sha256-dZJhY8hmLf4fwykvkF6U4lbaq1UqKE8ubf3FEx0rJXM=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    ffmpeg
    freeimage
    freetype
    gettext
    harfbuzz
    icu
    libgit2
    curl
    pugixml
    SDL2
    alsa-lib
    bluez
    libGL
    lunasvg
    poppler
    rlottie
  ];

  env.NIX_CFLAGS_COMPILE = "-march=native";
  env.NIX_CXXFLAGS_COMPILE = "-march=native";

  cmakeFlags = [
    "-DAPPLICATION_UPDATER=off"
  ];

  meta = with lib; {
    description = "ES-DE Frontend (EmulationStation Desktop Edition)";
    homepage = "https://es-de.org/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "es-de";
  };
})
#
