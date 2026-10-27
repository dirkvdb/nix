{
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeText,
  pkg-config,
  cmake,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  cacert,
  imagemagick,
  alsa-lib,
  fontconfig,
  freetype,
  libxkbcommon,
  libxcb,
  libX11,
  openssl,
  udev,
  vulkan-loader,
  wayland,
  xdg-utils,
  zstd,
}:
let
  family = builtins.fromJSON (builtins.readFile ../../configs/themes/charcoal-grove.json);
  colorKeys = {
    background = "background";
    foreground = "text";
    accent = "text.accent";
    content = "editor.background";
    panel = "panel.background";
    raised = "elevated_surface.background";
    selected = "element.selected";
    text_selection = "element.selected";
    sidebar_selected = "element.selected";
    border = "border";
    hover = "ghost_element.hover";
    muted = "text.muted";
  };
  generatePreset =
    appearance:
    let
      theme = lib.findFirst (
        theme: theme.appearance == appearance
      ) (throw "panda-reader: missing Charcoal Grove ${appearance} theme") family.themes;
    in
    ''
      const CHARCOAL_GROVE_${lib.toUpper appearance}: Preset = Preset {
          id: "charcoal_grove_${appearance}",
          name: ${builtins.toJSON theme.name},
          dark: ${lib.boolToString (appearance == "dark")},
          shadow: true,
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              field: key:
              # Preset stores opaque RGB; the shared light theme uses RGBA notation.
              "${field}: 0x${builtins.substring 1 6 theme.style.${key}},"
            ) colorKeys
          )}
      };
    '';
  presets = writeText "panda-reader-charcoal-grove.rs" (
    generatePreset "dark" + generatePreset "light"
  );
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "panda-reader";
  version = "0.2.12";

  src = fetchFromGitHub {
    owner = "yuhangch";
    repo = "panda-reader";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cE/FU01uR4EpcIaMvu4bju19Fp4VFryK50F0kzleup8=";
  };

  cargoHash = "sha256-AC4omho/3KlSqeaaWhbgwyAxbZHEwRT6loAShxEzX6s=";
  cargoBuildFlags = [
    "-p"
    "panda-reader"
    "--bin"
    "panda-reader"
  ];
  # Exercise the non-GUI library tests; the desktop binary has no test harness.
  cargoTestFlags = [ "--workspace" ];
  # The WebDAV transport test constructs a TLS client, even for its local probe.
  nativeCheckInputs = [ cacert ];

  postPatch = ''
    cp ${presets} apps/panda-reader/src/ui/charcoal-grove.rs
    substituteInPlace apps/panda-reader/src/ui/theme.rs \
      --replace-fail 'pub const PRESETS: &[Preset] = &[' 'include!("charcoal-grove.rs");
    pub const PRESETS: &[Preset] = &[
        CHARCOAL_GROVE_DARK,
        CHARCOAL_GROVE_LIGHT,' \
      --replace-fail '        DEFAULT_THEME_ID,' '        "bamboo",'
    substituteInPlace apps/panda-reader/src/app/preferences.rs \
      --replace-fail 'pub const DEFAULT_THEME_ID: &str = "bamboo";' \
        'pub const DEFAULT_THEME_ID: &str = "charcoal_grove_dark";'
    substituteInPlace apps/panda-reader/src/ui/theme.rs \
      --replace-fail 'use crate::app::preferences::DEFAULT_THEME_ID;' ""
  '';

  nativeBuildInputs = [
    cmake
    copyDesktopItems
    imagemagick
    makeWrapper
    pkg-config
    rustPlatform.bindgenHook
  ];
  buildInputs = [
    alsa-lib
    fontconfig
    freetype
    libxkbcommon
    libxcb
    libX11
    openssl
    udev
    vulkan-loader
    wayland
    zstd
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "panda-reader";
      desktopName = "Panda Reader";
      comment = "Local-first RSS reader";
      exec = "panda-reader";
      icon = "panda-reader";
      categories = [
        "Network"
        "News"
      ];
      startupWMClass = "panda-reader";
    })
  ];

  postInstall = ''
    install -Dm644 ${./icon.svg} $out/share/icons/hicolor/scalable/apps/panda-reader.svg
    for size in 32 48 64 128 256 512; do
      iconDir="$out/share/icons/hicolor/"$size"x"$size"/apps"
      mkdir -p "$iconDir"
      magick -background none ${./icon.svg} -resize "$size"x"$size" "$iconDir/panda-reader.png"
    done
    wrapProgram $out/bin/panda-reader \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
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
  '';

  meta = {
    description = "Local-first RSS reader with the Charcoal Grove themes";
    homepage = "https://github.com/yuhangch/panda-reader";
    license = lib.licenses.mit;
    mainProgram = "panda-reader";
    platforms = lib.platforms.linux;
  };
})
