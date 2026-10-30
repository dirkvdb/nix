{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  cmake,
  dbus,
  wayland,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxrender,
  libxext,
  libxcb,
}:
let
  runtimeLibs = [
    dbus
    wayland
    libxkbcommon
    libglvnd
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
    libxrender
    libxext
    libxcb
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "solidcraft";
  version = "0.27.1";

  src = fetchFromGitHub {
    owner = "tangency-labs";
    repo = "solidcraft";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+Uqg547kZy+G5zXEq7fmWcdNTDJbb/mE1liHFSF3gWw=";
  };

  cargoHash = "sha256-1NgLIlTgzjvwpPvd7KPs1eON1IW4pTskk5uicmkdwgQ=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    cmake
  ];
  buildInputs = runtimeLibs;

  cargoBuildFlags = [
    "-p"
    "solidcraft"
    "-p"
    "solidcraft-cli"
  ];
  cargoInstallFlags = finalAttrs.cargoBuildFlags;

  # Upstream's CI test gate requires a GPU and a wasm target.
  doCheck = false;

  postInstall = ''
    install -Dm644 assets/platforms/linux/io.tangencylabs.solidcraft.desktop \
      $out/share/applications/io.tangencylabs.solidcraft.desktop
    install -Dm644 assets/platforms/linux/io.tangencylabs.solidcraft.mime.xml \
      $out/share/mime/packages/io.tangencylabs.solidcraft.xml
    for size in 16 24 32 48 64 128 256 512; do
      install -Dm644 assets/icons/app/linux/exports/hicolor/''${size}x''${size}/apps/io.tangencylabs.solidcraft.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/io.tangencylabs.solidcraft.png
    done
  '';

  postFixup = ''
    for program in solidcraft solidcraft-cli; do
      wrapProgram $out/bin/$program \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}:/run/opengl-driver/lib" \
        --prefix XDG_DATA_DIRS : "$out/share:/run/opengl-driver/share"
    done
  '';

  meta = {
    description = "Parametric 3D CAD application with a headless CLI and MCP server";
    homepage = "https://github.com/tangency-labs/solidcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "solidcraft";
    platforms = lib.platforms.linux;
  };
})
