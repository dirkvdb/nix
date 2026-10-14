{
  nativePkgs,
  armPkgs,
  crossPkgs,
}:
let
  inherit (nativePkgs) lib;
  buildPkgs = crossPkgs.buildPackages;

  # Cached native Qt's dev output propagates ARM build tools. Keep its target
  # metadata and libraries, but adapt the setup hook and native propagation.
  qtbaseDev = nativePkgs.runCommand "qtbase-arm-cross-dev" { } ''
    mkdir -p "$out"
    for path in ${armPkgs.qt6.qtbase.dev}/*; do
      name="''${path##*/}"
      if [ "$name" != nix-support ]; then
        ln -s "$path" "$out/$name"
      fi
    done
    cp -r ${armPkgs.qt6.qtbase.dev}/nix-support "$out/nix-support"
    chmod -R u+w "$out/nix-support"
    substituteInPlace "$out/nix-support/setup-hook" \
      --replace-fail '${armPkgs.qt6.qtbase}/bin/qmake' '${buildPkgs.qt6.qtbase}/bin/qmake'
    printf '%s\n' ${buildPkgs.lndir} ${buildPkgs.wayland} ${lib.getBin buildPkgs.wayland-scanner} \
      > "$out/nix-support/propagated-native-build-inputs"
  '';
  qtbase = armPkgs.qt6.qtbase // {
    dev = qtbaseDev;
  };

  # Do not put native qttools itself in nativeBuildInputs: it propagates native
  # Qt libraries and a second qtbase setup hook. Expose only executable tools
  # and their CMake packages, not native Qt library discovery metadata.
  qttools = nativePkgs.runCommand "qt6-cross-native-tools" { } ''
    mkdir -p "$out/bin" "$out/libexec" "$out/lib/cmake"
    for package in ${buildPkgs.qt6.qtbase} ${buildPkgs.qt6.qttools}; do
      for directory in bin libexec; do
        for path in "$package/$directory"/*; do
          [ -e "$path" ] || continue
          ln -s "$path" "$out/$directory/''${path##*/}"
        done
      done
      for path in "$package/lib/cmake/"*Tools "$package/lib/cmake/Qt6HostInfo"; do
        [ -d "$path" ] || continue
        ln -s "$path" "$out/lib/cmake/''${path##*/}"
      done
    done
  '';

  # Retain the cross-aware binary wrapper hook, with cached ARM plugin paths.
  qt6 = crossPkgs.qt6.overrideScope (
    _final: _prev: {
      inherit qtbase qttools;
      inherit (armPkgs.qt6) qtsvg qtwayland qtwebsockets;
      wrapQtAppsHook = crossPkgs.qt6.wrapQtAppsHook.override {
        inherit qtbase;
        inherit (buildPkgs) makeBinaryWrapper;
      };
    }
  );

  # GPUI's include-flate procedural macro links zstd on x86, independently of
  # the application's ARM zstd dependency. Never let it discover ARM metadata.
  withZstd =
    package:
    package.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nativePkgs.zstd ];
      buildInputs = (old.buildInputs or [ ]) ++ [ armPkgs.zstd ];
      env = (old.env or { }) // {
        PKG_CONFIG_x86_64_unknown_linux_gnu = "${nativePkgs.pkg-config}/bin/pkg-config";
        PKG_CONFIG_PATH_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
        PKG_CONFIG_LIBDIR_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
      };
    });
in
{

  make-slack-great-again =
    (crossPkgs.callPackage ../make-slack-great-again/default.nix {
      inherit qt6;
      inherit (armPkgs) openssl;
      inherit (buildPkgs) cmake ninja;
    }).overrideAttrs
      (old: {
        strictDeps = true;
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DQT_HOST_PATH=${buildPkgs.qt6.qtbase}"
          "-DQT_HOST_PATH_CMAKE_DIR=${buildPkgs.qt6.qtbase}/lib/cmake"
          "-DQt6HostInfo_DIR=${buildPkgs.qt6.qtbase}/lib/cmake/Qt6HostInfo"
          "-DQT_ADDITIONAL_HOST_PACKAGES_PREFIX_PATH=${buildPkgs.qt6.qttools}"
        ];
      });

  siffra = withZstd (
    crossPkgs.callPackage ../siffra/default.nix {
      inherit (armPkgs)
        alsa-lib
        fontconfig
        freetype
        libdrm
        libva
        libxkbcommon
        libxcb
        mesa
        openssl
        vulkan-loader
        wayland
        zlib
        ;
      inherit (buildPkgs) pkg-config cmake makeWrapper;
    }
  );

  gliff =
    (crossPkgs.callPackage ../gliff/default.nix {
      inherit (armPkgs)
        dbus
        gtk4
        libadwaita
        libdrm
        libgbm
        libva
        libxkbcommon
        openssh
        vulkan-loader
        wayland
        ;
      inherit (buildPkgs) pkg-config nasm;
      wrapGAppsHook4 = crossPkgs.wrapGAppsHook4.override {
        inherit (armPkgs) dconf librsvg;
        gtk3 = armPkgs.gtk4;
        inherit (buildPkgs) makeWrapper;
      };
    }).overrideAttrs
      (old: {
        # Cached ARM Avahi needs the native GCC libssp's fortified printf symbols.
        env = (old.env or { }) // {
          NIX_LDFLAGS = "-L${armPkgs.stdenv.cc.cc.lib}/lib -lssp";
        };
      });

  oweka = crossPkgs.callPackage ../oweka/default.nix { };

  omasend = withZstd (
    crossPkgs.callPackage ../omasend/default.nix {
      inherit (armPkgs)
        cacert
        coreutils
        runtimeShell
        fontconfig
        freetype
        libxkbcommon
        libxcb
        libX11
        openssl
        vulkan-loader
        wayland
        wl-clipboard
        xdg-utils
        zstd
        ;
      inherit (buildPkgs)
        pkg-config
        cmake
        makeWrapper
        imagemagick
        ;
      inherit (nativePkgs) writeText;
    }
  );
}
