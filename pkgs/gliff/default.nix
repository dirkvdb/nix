{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  nasm,
  wrapGAppsHook4,
  dbus,
  gtk4,
  libadwaita,
  libdrm,
  libgbm,
  libva,
  libxkbcommon,
  openssh,
  vulkan-loader,
  wayland,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gliff";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "gliff";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7tE/Gsf3RkeSKqESn+6GMq0vZpZA1miWH3pUiyqUs3E=";
  };

  cargoHash = "sha256-dZ6DVDGyvrWpORgE87EUfZjVHh7JS6UiSRWHojLeCXA=";

  nativeBuildInputs = [
    pkg-config
    nasm
    wrapGAppsHook4
  ];

  buildInputs = [
    dbus
    gtk4
    libadwaita
    libdrm
    libgbm
    libva
    libxkbcommon
    wayland
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [ openssh ]}"
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ vulkan-loader ]}"
    )
  '';

  postInstall = ''
    install -Dm644 pkgbuild/gliff.desktop $out/share/applications/gliff.desktop
    install -Dm644 pkgbuild/gliff.svg $out/share/icons/hicolor/scalable/apps/gliff.svg
    install -Dm644 LICENSE $out/share/licenses/gliff/LICENSE
    install -Dm644 NOTICE $out/share/licenses/gliff/NOTICE
  '';

  meta = {
    description = "Hyprland remote desktop over SSH with GPU-accelerated H.264 video";
    homepage = "https://github.com/omacom/gliff";
    license = [
      lib.licenses.mit
      lib.licenses.bsd2
    ];
    mainProgram = "gliff";
    platforms = lib.platforms.linux;
  };
})
