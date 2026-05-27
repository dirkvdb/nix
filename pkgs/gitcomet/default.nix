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
  mesa,
  openssl,
  vulkan-loader,
  wayland,
  libx11,
  libxcb,
  zlib,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gitcomet";
  version = "0.1.15";

  src = fetchFromGitHub {
    owner = "Auto-Explore";
    repo = "GitComet";
    rev = "f4c18cd8c6618d280c9e0664c29146876d925636";
    hash = "sha256-EDqBqdeB8zerLo3LHhGTUMTCMaf95LrIeQcJiorBi14=";
  };

  cargoHash = "sha256-jIMsS4BcDkJ54E6iFz9YQS1vVXhX0yYxMMFxY8ExMm0=";

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
    mesa
    openssl
    vulkan-loader
    wayland
    libx11
    libxcb
    zlib
  ];

  cargoExtraArgs = "--package gitcomet --features ui-gpui,gix";

  doCheck = false;

  postPatch = ''
    # gpui-ce-macros uses paths relative to its original workspace location
    # (tooling/macros/src/), resolving 3 levels up to <workspace-root>/src/.
    # cargo vendor flattens the workspace into source-git-1/gpui-ce-macros-0.1.0/,
    # so the 3-level ../../../ lands at the vendor root, not source-git-1/.
    # $cargoDepsCopy is set by cargoSetupPostUnpackHook and still available here.
    local gpui_src="$cargoDepsCopy/source-git-1/gpui-ce-0.3.3/src"
    mkdir -p "$cargoDepsCopy/src/refineable"
    cp "$gpui_src/refineable/derive_refineable.rs" \
       "$cargoDepsCopy/src/refineable/derive_refineable.rs"
    mkdir -p "$cargoDepsCopy/src/util"
    cp "$gpui_src/util/util_macros.rs" \
       "$cargoDepsCopy/src/util/util_macros.rs"
  '';

  postInstall = ''
    install -Dm644 assets/linux/gitcomet.desktop \
      $out/share/applications/gitcomet.desktop
    install -Dm644 assets/gitcomet-512.png \
      $out/share/icons/hicolor/512x512/apps/gitcomet.png
    wrapProgram $out/bin/gitcomet \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        alsa-lib
        libdrm
        libva
        libxkbcommon
        mesa
        vulkan-loader
        wayland
        libx11
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
