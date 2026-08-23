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
  pname = "siffra";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "ImpossibleReality";
    repo = "Siffra";
    rev = "v0.3.2";
    hash = "sha256-G5kG8xvwSQR3bFggSLadK3CvNlbrvsT6QgqFDD7TPfc=";
  };

  cargoHash = "sha256-SF042IVbjiEngn+MIpLmL99ZSSkwhelA452AwZuCpzo=";

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

  cargoExtraArgs = "--package siffra-desktop";

  doCheck = false;

  postInstall = ''
    mv $out/bin/siffra-desktop $out/bin/siffra
    wrapProgram $out/bin/siffra \
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

    install -Dm644 desktop/assets/app_icons/icon.png \
      $out/share/icons/hicolor/128x128/apps/siffra.png
    install -Dm644 /dev/stdin $out/share/applications/siffra.desktop <<EOF
    [Desktop Entry]
    Name=Siffra
    Comment=A fast and accurate calculator with dimensional analysis
    Exec=$out/bin/siffra
    Icon=siffra
    Terminal=false
    Type=Application
    Categories=Utility;Calculator;
    StartupWMClass=siffra
    EOF
  '';

  meta = {
    description = "A fast and accurate calculator app";
    longDescription = ''
      Siffra is a lightweight, fast, and accurate calculator with support for dimensional analysis built with GPUI and Rust.
    '';
    homepage = "https://github.com/ImpossibleReality/Siffra";
    license = lib.licenses.mit;
    mainProgram = "siffra";
    platforms = lib.platforms.linux;
  };
})
