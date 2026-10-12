{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  writeText,
  pkg-config,
  cmake,
  makeWrapper,
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
let
  family = builtins.fromJSON (builtins.readFile ../../configs/themes/charcoal-grove.json);

  colorKeys = {
    background = "background";
    surface = "surface.background";
    inset = "editor.background";
    foreground = "text";
    secondary = "text.muted";
    bright = "terminal.bright_foreground";
    accent = "text.accent";
    on_accent = "editor.background";
    selection = "element.selected";
    border = "border";
    danger = "error";
    warning = "warning";
    success = "success";
  };
  generateTheme =
    appearance:
    let
      theme = lib.findFirst (
        theme: theme.appearance == appearance
      ) (throw "omasend: missing Charcoal Grove ${appearance} theme") family.themes;
      colors = theme.style // {
        "syntax.operator" = theme.style.syntax.operator.color;
      };
      color =
        key:
        let
          hex = lib.removePrefix "#" colors.${key};
          constructor = if builtins.stringLength hex == 8 then "rgba" else "rgb";
        in
        "gpui_kit::${constructor}(0x${hex}).into()";
      rustAppearance = if appearance == "light" then "Light" else "Dark";
    in
    ''
      fn charcoal_grove_${appearance}() -> Theme {
          Theme {
              name: ${builtins.toJSON theme.name}.into(),
              appearance: gpui_kit::base::ThemeAppearance::${rustAppearance},
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (field: key: "${field}: ${color key},") colorKeys
              )}
              chart: [${
                lib.concatMapStringsSep ", " color [
                  "text.accent"
                  "syntax.operator"
                  "info"
                  "terminal.ansi.blue"
                  "success"
                ]
              }],
              // Keep the library's platform-specific font defaults.
              ..Theme::tokyo_night()
          }
      }
    '';
  charcoalGrove = writeText "omasend-charcoal-grove.rs" (
    generateTheme "dark" + generateTheme "light"
  );
in
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

  patches = [ ./charcoal-grove.patch ];

  postPatch = ''
    cp ${charcoalGrove} src/views/charcoal-grove.rs
    substituteInPlace tests/wayland.rs \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}' \
      --replace-fail '/bin/cat' '${coreutils}/bin/cat'
  '';

  nativeBuildInputs = [
    cmake
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

  preCheck = ''
    export HOME="$TMPDIR/omasend-home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_RUNTIME_DIR="$TMPDIR/omasend-runtime"
    mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
  '';

  # Run only the theme-specific UI checks; other UI tests depend on font/layout fixtures.
  postCheck = ''
    cargo test --offline --locked -j "$NIX_BUILD_CORES" --profile release \
      --target ${stdenv.hostPlatform.rust.rustcTarget} \
      --features ui-tests --bin omasend packaged_theme_
  '';

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
    install -Dm644 assets/omasend.png $out/share/icons/hicolor/1024x1024/apps/omasend.png
  '';

  meta = {
    description = "Native LocalSend client with the Charcoal Grove theme";
    homepage = "https://github.com/huacnlee/omasend";
    license = lib.licenses.mit;
    mainProgram = "omasend";
    platforms = lib.platforms.linux;
  };
})
