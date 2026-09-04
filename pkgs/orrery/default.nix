{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  git,
  makeWrapper,
  alsa-lib,
  fontconfig,
  freetype,
  libdrm,
  libxcb,
  libxkbcommon,
  openssl,
  vulkan-loader,
  wayland,
  zlib,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "orrery";
  version = "2026.7.1";

  src = fetchFromGitHub {
    owner = "Hankanman";
    repo = "Orrery";
    rev = "edd996c51f2c8ca03254066a25be540a20b52c1b";
    hash = "sha256-uKVv6bshrb/sEWoqmT8IoxzPuHLZMtrPYWjO7TQ+2dk=";
  };

  cargoHash = "sha256-H0IDYy+Js0+gcrX1UUG7ZtXvCmUyM2OEKqCNAhgdyME=";

  nativeBuildInputs = [
    cmake
    git
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    fontconfig
    freetype
    libdrm
    libxcb
    libxkbcommon
    openssl
    vulkan-loader
    wayland
    zlib
  ];

  cargoBuildFlags = [ "--package" "orrery" ];

  postInstall = ''
    wrapProgram $out/bin/orrery \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        libxcb
        libxkbcommon
        vulkan-loader
        wayland
      ]}

    install -Dm644 packaging/orrery.desktop \
      $out/share/applications/orrery.desktop
    for size in 32 64 128; do
      install -Dm644 packaging/icons/$size\x$size.png \
        $out/share/icons/hicolor/$size\x$size/apps/orrery.png
    done
    install -Dm644 packaging/icons/128x128@2x.png \
      $out/share/icons/hicolor/256x256/apps/orrery.png
  '';

  meta = {
    description = "A Linux-native command center for all your git repositories";
    homepage = "https://github.com/Hankanman/Orrery";
    license = lib.licenses.mit;
    mainProgram = "orrery";
    platforms = lib.platforms.linux;
  };
})
