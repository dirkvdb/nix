{
  lib,
  stdenv,
  fetchFromGitLab,
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
  version = "3.5.0";

  src = fetchFromGitLab {
    owner = "es-de";
    repo = "emulationstation-de";
    rev = "v${finalAttrs.version}";
    forceFetchGit = true;
    hash = "sha256-MFCLE8RnpvSAYY4UhJ+uwdIlhlyJsiLjSUUAJrNgd1c=";
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

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isx86_64 "-march=x86-64-v3";
  env.NIX_CXXFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isx86_64 "-march=x86-64-v3";

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
