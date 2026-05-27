{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  libGL,
  libxkbcommon,
  wayland,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxcb,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rproc";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "Trystan-SA";
    repo = "rproc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-nSoUwhQZSuY5aaKAr9+WOH7xbpa2Qf49hFoufYKbZSI=";
  };

  cargoHash = "sha256-RNuHzvThIKQNXvyDUSfu3cC6QS2tvje+TqR4w6KoD+Y=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    libGL
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
  ];

  doCheck = false;

  postInstall = ''
    install -Dm644 packaging/io.github.trystan_sa.rproc.desktop \
      $out/share/applications/io.github.trystan_sa.rproc.desktop
    install -Dm644 packaging/icons/hicolor/scalable/apps/io.github.trystan_sa.rproc.svg \
      $out/share/icons/hicolor/scalable/apps/io.github.trystan_sa.rproc.svg
    install -Dm644 packaging/rprocd.service \
      $out/lib/systemd/user/rprocd.service
    wrapProgram $out/bin/rproc \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        libGL
        libxkbcommon
        wayland
        libx11
        libxcursor
        libxi
        libxrandr
        libxcb
      ]}"
  '';

  meta = {
    description = "Resource & process monitor for Linux, inspired by Windows 11 Task Manager";
    homepage = "https://github.com/Trystan-SA/rproc";
    changelog = "https://github.com/Trystan-SA/rproc/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "rproc";
    platforms = lib.platforms.linux;
  };
})

