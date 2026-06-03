{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  makeFontsConf,
  freefont_ttf,
  fontconfig,
  libxkbcommon,
  wayland,
  xorg,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rproc";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "Trystan-SA";
    repo = "rproc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-EHeiY/zlJLOlLmoAU0x7e2K4SNq65PQZhLQFSoHpG8U=";
  };

  cargoHash = "sha256-mMSiYimfkcX5p2SV8jmNwGg/HAeaI3SOYeTRsA8eR+s=";

  env.FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ freefont_ttf ]; };

  preBuild = ''
    export XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$XDG_CACHE_HOME/fontconfig"
    export LD_LIBRARY_PATH="${fontconfig.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    fontconfig
  ];

  buildInputs = [
    fontconfig
    libxkbcommon
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libxcb
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
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          fontconfig
          libxkbcommon
          wayland
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
          xorg.libxcb
        ]
      }"
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
