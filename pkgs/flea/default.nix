{
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
  localsend-cli,
  tailscale,
  pkg-config,
  makeWrapper,
  cmake,
  alsa-lib,
  bat,
  bubblewrap,
  bzip2,
  coreutils,
  expect,
  ffmpegthumbnailer,
  fontconfig,
  gdk-pixbuf,
  git,
  gzip,
  glycin-thumbnailer,
  glib,
  gvfs,
  hicolor-icon-theme,
  hyprland,
  imagemagick,
  jq,
  libarchive,
  libglvnd,
  libxcb,
  libxkbcommon,
  mpv,
  poppler,
  p7zip,
  poppler-utils,
  python3,
  quickjs-ng,
  qt6,
  ripgrep,
  shared-mime-info,
  stdenv,
  udisks2,
  usbmuxd,
  util-linux,
  vulkan-loader,
  wayland,
  wl-clipboard,
  xdg-terminal-exec,
  xdg-utils,
  xz,
  zoxide,
  zstd,
}:
let
  version = "0.4.0";
  omarchyTailscaleSend = writeShellScriptBin "omarchy-tailscale-send" ''
    set -euo pipefail
    if (( $# < 2 )); then
      echo "Usage: omarchy-tailscale-send <machine> <file>..." >&2
      exit 2
    fi
    machine="$1"
    shift
    exec ${tailscale}/bin/tailscale file cp --update-interval=0 -- "$@" "$machine:"
  '';
  runtimeLibs = [
    alsa-lib
    fontconfig
    gdk-pixbuf
    glib
    libglvnd
    libxcb
    libxkbcommon
    mpv
    poppler
    qt6.qtmultimedia
    qt6.qtdeclarative
    qt6.qtwebengine
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
  ];
  runtimeInputs = runtimeLibs ++ [
    bat
    bubblewrap
    bzip2
    coreutils
    expect
    ffmpegthumbnailer
    git
    glycin-thumbnailer
    gzip
    gvfs
    hicolor-icon-theme
    hyprland
    imagemagick
    jq
    libarchive
    localsend-cli
    poppler-utils
    quickjs-ng
    ripgrep
    shared-mime-info
    tailscale
    omarchyTailscaleSend
    p7zip
    udisks2
    usbmuxd
    util-linux
    wl-clipboard
    xdg-terminal-exec
    xdg-utils
    xz
    zoxide
    zstd
    (python3.withPackages (ps: [ ps.pygobject3 ]))
  ];
in
rustPlatform.buildRustPackage {
  pname = "flea";
  inherit version;

  src = fetchFromGitHub {
    owner = "thisisgm";
    repo = "flea";
    tag = "v${version}";
    hash = "sha256-zzGFgcpA2D3AwGKjt8H1cz9mwi/i/iqBNB4xLl35bZg=";
  };

  patches = [ ./system-icons.patch ];

  cargoHash = "sha256-eOl8EtxMEKpwRancasWjtYQ+su7WCpppiCtZ+rZ+WMU=";
  cargoBuildFlags = [
    "--workspace"
    "--bins"
  ];
  doCheck = false;
  cargoTestFlags = [
    "--package"
    "flea-gui"
    "--lib"
    "row::marks::system_icons"
  ];
  preCheck = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"
  '';
  dontWrapQtApps = true;

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
  ];

  buildInputs = runtimeLibs;

  postPatch = ''
        old="$(printf '%s\n' '    "/usr",' '    "/usr",' '    "--ro-bind",' '    "/etc",' '    "/etc",')"
        new="$(printf '%s\n' '    "/usr",' '    "/usr",' '    "--ro-bind",' '    "/nix",' '    "/nix",' '    "--ro-bind",' '    "/etc",' '    "/etc",')"
        substituteInPlace src/backend/sandbox.rs --replace-fail "$old" "$new"
        # Store binaries are already mounted read-only. FHS user namespaces map
        # their root owner to nobody, so rebinding them fails the external-tool check.
        substituteInPlace src/backend/thumbbind.rs \
          --replace-fail 'const JAIL_ROOTS: [&str; 6] = ["/usr", "/etc", "/bin", "/sbin", "/lib", "/lib64"];' \
            'const JAIL_ROOTS: [&str; 7] = ["/usr", "/etc", "/bin", "/sbin", "/lib", "/lib64", "/nix/store"];' \
          --replace-fail 'const MOUNTED: [&str; 2] = ["/usr", "/etc"];' \
            'const MOUNTED: [&str; 3] = ["/usr", "/etc", "/nix/store"];'
        # The media sandbox re-execs the Nix ELF directly, so restore its packaged
        # library path after --clearenv removes the wrapper environment.
        substituteInPlace crates/flea-gui/src/g2/pv3/sandbox.rs \
          --replace-fail '        "--clearenv",' '        "--clearenv",
                "--ro-bind",
                "/nix/store",
                "/nix/store",
                "--setenv",
                "LD_LIBRARY_PATH",
                "${lib.makeLibraryPath runtimeLibs}",'
        # PulseAudio clients need a home path and may need the session auth cookie.
        # Give the helper a private HOME and mount only the cookie file, not user config.
        substituteInPlace crates/flea-gui/src/g2/pv3/sandbox.rs \
          --replace-fail '        "--tmpfs",
            "/tmp",' '        "--tmpfs",
            "/tmp",
            "--setenv",
            "HOME",
            "/tmp",' \
          --replace-fail 'fn pulse_socket() -> Option<PathBuf> {' 'fn pulse_cookie() -> Option<PathBuf> {
        let config = std::env::var_os("XDG_CONFIG_HOME")
            .map(PathBuf::from)
            .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".config")));
        let runtime = std::env::var_os("XDG_RUNTIME_DIR")
            .map(|dir| PathBuf::from(dir).join("pulse/cookie"));
        [
            std::env::var_os("PULSE_COOKIE").map(PathBuf::from),
            config.map(|dir| dir.join("pulse/cookie")),
            runtime,
        ]
        .into_iter()
        .flatten()
        .find(|path| path.is_file())
    }

    fn pulse_socket() -> Option<PathBuf> {' \
          --replace-fail '    let options = Options {' '    if pulse.is_some() {
            if let Some(cookie) = pulse_cookie() {
                words.extend([
                    "--ro-bind".into(),
                    cookie.display().to_string(),
                    "/pulse-cookie".into(),
                    "--setenv".into(),
                    "PULSE_COOKIE".into(),
                    "/pulse-cookie".into(),
                ]);
            }
        }
        let options = Options {'
        substituteInPlace src/defaults.rs \
          --replace-fail '/usr/lib/flea/flea-filemanager1' \
            '${placeholder "out"}/lib/flea/flea-filemanager1'
  '';

  postInstall = ''
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTarget}/release/flea-gui $out/bin/flea-gui

    install -Dm755 tools/flea-gio-auth $out/lib/flea/flea-gio-auth
    install -Dm755 tools/flea-udisks $out/lib/flea/flea-udisks
    install -Dm755 tools/flea-portal $out/lib/flea/flea-portal
    install -Dm755 tools/flea-filemanager1 $out/lib/flea/flea-filemanager1
    install -Dm755 tools/flea-mpris $out/lib/flea/flea-mpris

    install -Dm644 packaging/flea.portal $out/share/xdg-desktop-portal/portals/flea.portal
    install -Dm644 packaging/org.freedesktop.impl.portal.desktop.flea.service \
      $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.flea.service
    install -Dm644 packaging/com.thisisgm.flea.FileManager1.service \
      $out/share/dbus-1/services/com.thisisgm.flea.FileManager1.service
    install -Dm644 packaging/com.thisisgm.flea.desktop \
      $out/share/applications/com.thisisgm.flea.desktop
    install -Dm644 packaging/com.thisisgm.flea.svg \
      $out/share/icons/hicolor/scalable/apps/com.thisisgm.flea.svg
    install -Dm644 LICENSE THIRD-PARTY-LICENSES.txt -t $out/share/licenses/flea

    install -Dm644 ui/qmldir ui/*.qml ui/*.js -t $out/share/flea/ui
    install -Dm644 ui/js/*.js ui/js/*.mjs -t $out/share/flea/ui/js
    install -Dm644 ui/vendor/*.mjs -t $out/share/flea/ui/vendor
    install -Dm644 ui/vendor/LICENSES/* -t $out/share/flea/ui/vendor/LICENSES
    install -Dm644 ui/boot/shell.qml ui/boot/picker.qml ui/boot/fleatab.qml \
      ui/boot/tabtearoff.qml -t $out/share/flea/ui/boot
    install -Dm644 shelf/manifest.json shelf/README.md shelf/*.qml shelf/*.js \
      -t $out/share/flea/shelf
    for catalog in i18n/*/flea.json; do
      install -Dm644 "$catalog" "$out/share/flea/$catalog"
    done

    substituteInPlace $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.flea.service \
      --replace-fail '/usr/lib/flea/flea-portal' "$out/lib/flea/flea-portal"
    substituteInPlace $out/share/dbus-1/services/com.thisisgm.flea.FileManager1.service \
      --replace-fail '/usr/lib/flea/flea-filemanager1' "$out/lib/flea/flea-filemanager1"
    substituteInPlace $out/lib/flea/flea-portal $out/lib/flea/flea-filemanager1 \
      --replace-fail '/usr/bin/flea' "$out/bin/flea"
  '';

  postFixup = ''
    wrapProgram $out/bin/flea \
      --set FLEA_UI $out/share/flea/ui \
      --set FLEA_BIN $out/bin/flea \
      --prefix PATH : ${lib.makeBinPath runtimeInputs} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
    wrapProgram $out/bin/flea-gui \
      --prefix PATH : ${lib.makeBinPath runtimeInputs} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
  '';

  passthru = { inherit runtimeInputs; };

  meta = {
    description = "Fast, keyboard-first file manager for Omarchy";
    homepage = "https://github.com/thisisgm/flea";
    license = with lib.licenses; [
      asl20
      bsd2
      bsd3
      cc0
      isc
      mit
      mpl20
      unicode-30
      zlib
    ];
    mainProgram = "flea";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
