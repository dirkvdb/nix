{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  makeWrapper,
  alsa-lib,
  fontconfig,
  freetype,
  libdrm,
  libva,
  libxkbcommon,
  libxcb,
  mesa,
  openssl,
  vulkan-loader,
  wayland,
  zlib,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gitcomet";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "Auto-Explore";
    repo = "GitComet";
    rev = "a080af0358ecc1e765f9a7a92d895321082598e7";
    hash = "sha256-VRd3HHYuHfOebAT3yC5Tv4CJdFUJkZJHQ8vTzY78OQ0=";
  };

  cargoHash = "sha256-L/UXaXC1zymbNfv7SGmOYSvUy/767mAWqL+3jwJwWcE=";

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    fontconfig
    freetype
    libdrm
    libva
    libxkbcommon
    openssl
    libxcb
    zlib
  ];

  cargoExtraArgs = "--package gitcomet --features ui-gpui,gix";

  doCheck = false;

  postInstall = ''
    install -Dm644 assets/linux/gitcomet.desktop \
      $out/share/applications/gitcomet.desktop
    substituteInPlace $out/share/applications/gitcomet.desktop \
      --replace-fail 'Exec=gitcomet' "Exec=$out/bin/gitcomet"
    install -Dm644 assets/gitcomet-512.png \
      $out/share/icons/hicolor/512x512/apps/gitcomet.png
    wrapProgram $out/bin/gitcomet \
      --unset DISPLAY \
      --set GITCOMET_NO_DESKTOP_INSTALL 1 \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          alsa-lib
          libdrm
          libva
          libxkbcommon
          mesa
          vulkan-loader
          wayland
          libxcb
        ]
      }"
  '';

  meta = {
    description = "Fastest open-source Git GUI";
    longDescription = ''
      GitComet is a fast, local-first Git GUI for teams who want familiar
      workflows and open-source freedom. Built with GPUI for native performance
      on Linux, macOS, and Windows.
    '';
    homepage = "https://github.com/Auto-Explore/GitComet";
    changelog = "https://github.com/Auto-Explore/GitComet/releases/tag/${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "gitcomet";
    platforms = lib.platforms.linux;
  };
})
