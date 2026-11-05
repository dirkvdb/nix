{
  lib,
  rustPlatform,
  fetchFromGitHub,

  pkg-config,
  cmake,
  makeWrapper,
  imagemagick,
  cacert,
  coreutils,
  runtimeShell,
  fontconfig,
  freetype,
  libxkbcommon,
  libxcb,
  libX11,
  openssl,
  vulkan-loader,
  wayland,
  wl-clipboard,
  xdg-utils,
  zstd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "omasend";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "huacnlee";
    repo = "omasend";
    rev = "b4b63e39be05eb28b020b8138282f45b849d1614";
    hash = "sha256-UCRrsRlXzN59cMIB+ivyynyLUObHat8oKGSamNjY4+k=";
  };

  cargoHash = "sha256-I2NUQoGjaGRm+5f9qtp6Q1A4PZZ5Zto6CA2WmOwjhzo=";

  postPatch = ''

    substituteInPlace tests/wayland.rs \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}' \
      --replace-fail '/bin/cat' '${coreutils}/bin/cat'
  '';

  nativeBuildInputs = [
    cmake
    imagemagick
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    fontconfig
    freetype
    libxkbcommon
    libxcb
    libX11
    openssl
    vulkan-loader
    wayland
    zstd
  ];

  env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  postInstall = ''
    wrapProgram $out/bin/omasend \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --prefix PATH : ${
        lib.makeBinPath [
          fontconfig
          wl-clipboard
          xdg-utils
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          fontconfig
          libxkbcommon
          libxcb
          libX11
          vulkan-loader
          wayland
        ]
      }
    install -Dm644 packaging/omasend.desktop $out/share/applications/omasend.desktop
    # Noctalia prefers SVGs and rasterizes them at the requested display size.
    mkdir -p "$out/share/icons/hicolor/scalable/apps"
    substitute assets/logo.svg "$out/share/icons/hicolor/scalable/apps/omasend.svg" \
      --replace-fail 'fill="currentColor"' 'fill="#9ac357"'

    # Only indexed hicolor sizes are searched by desktop icon resolvers.
    for size in 32 48 64 128 256 512; do
      dimensions="$size"x"$size"
      iconDir="$out/share/icons/hicolor/$dimensions/apps"
      mkdir -p "$iconDir"
      magick assets/omasend.png -resize "$dimensions" "$iconDir/omasend.png"
    done
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -s "$out/share/icons/hicolor/scalable/apps/omasend.svg"
    for size in 32 48 64 128 256 512; do
      dimensions="$size"x"$size"
      icon="$out/share/icons/hicolor/$dimensions/apps/omasend.png"
      test "$(magick identify -format '%wx%h' "$icon")" = "$dimensions"
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "Native LocalSend client";
    homepage = "https://github.com/huacnlee/omasend";
    license = lib.licenses.mit;
    mainProgram = "omasend";
    platforms = lib.platforms.linux;
  };
})
