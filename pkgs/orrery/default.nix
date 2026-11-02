{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  git,
  makeWrapper,
  cacert,
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
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Hankanman";
    repo = "Orrery";
    tag = "v${finalAttrs.version}";
    hash = "sha256-o4yAvCfrDMPZyeO/uSwpVE3yR6R1IwcsxU/VZScS5Ec=";
  };

  cargoHash = "sha256-IcKg6bH9eTVunkMs9Zx0vwtddywi8p2Bc7WMMuRrN1Y=";

  patches = [ ./disable-tray.patch ];

  nativeBuildInputs = [
    cmake
    git
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];

  # The HTTP-client test loads the platform certificate store in the sandbox.
  nativeCheckInputs = [ cacert ];

  buildInputs = [
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

  cargoBuildFlags = [
    "--package"
    "orrery"
  ];

  postInstall = ''
    wrapProgram $out/bin/orrery \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libxcb
          libxkbcommon
          vulkan-loader
          wayland
        ]
      }

    install -Dm644 packaging/orrery.desktop \
      $out/share/applications/orrery.desktop
    install -Dm644 packaging/orrery-search-provider.ini \
      $out/share/gnome-shell/search-providers/orrery-search-provider.ini
    for size in 32 64 128; do
      install -Dm644 packaging/icons/$size\x$size.png \
        $out/share/icons/hicolor/$size\x$size/apps/orrery.png
    done
    install -Dm644 packaging/icons/128x128@2x.png \
      $out/share/icons/hicolor/256x256/apps/orrery.png
    install -Dm644 packaging/icons/icon.png \
      $out/share/icons/hicolor/512x512/apps/orrery.png
  '';

  meta = {
    description = "A Linux-native command center for all your git repositories";
    homepage = "https://github.com/Hankanman/Orrery";
    license = lib.licenses.mit;
    mainProgram = "orrery";
    platforms = lib.platforms.linux;
  };
})
