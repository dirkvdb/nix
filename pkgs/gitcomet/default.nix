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
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "Auto-Explore";
    repo = "GitComet";
    rev = "866913c8d136122c828a112ddd375e12df687a5a";
    hash = "sha256-kwb/XtqP6/4P7wcn4s+4fzpwZflGfReQ+QdKfBjf4hw=";
  };

  cargoHash = "sha256-XIpliBQh5RU3KiJxA6gbtrpfEsi9Iqt+x2OAINWNwNg=";

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
    install -Dm644 assets/gitcomet-512.png \
      $out/share/icons/hicolor/512x512/apps/gitcomet.png
    wrapProgram $out/bin/gitcomet \
      --unset DISPLAY \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        alsa-lib
        libdrm
        libva
        libxkbcommon
        mesa
        vulkan-loader
        wayland
        libxcb
      ]}"
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
