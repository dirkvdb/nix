{
  inputs,
  nativePkgs,
  armPkgs,
  crossPkgs,
}:
let
  inherit (nativePkgs) lib;
  buildPkgs = crossPkgs.buildPackages;
  isCross = crossPkgs.stdenv.buildPlatform != crossPkgs.stdenv.hostPlatform;
  buildSystem = nativePkgs.stdenv.hostPlatform.system;

  # The cross platform reuses the native compiler and adds the target stdlib.
  # Leave native checks intact when this recipe is used without cross compilation.
  rustPlatform = crossPkgs.rustPlatform // {
    buildRustPackage =
      args:
      crossPkgs.rustPlatform.buildRustPackage (
        args
        // lib.optionalAttrs isCross {
          doCheck = false;
          doInstallCheck = false;
        }
      );
  };

  linuxRuntimeDeps = with armPkgs; [
    fontconfig
    libxcb
    libxkbcommon
    wayland
    vulkan-loader
  ];
  guiBuildInputs = [
    armPkgs.fontconfig.dev
    armPkgs.vulkan-headers
    armPkgs.zstd
  ]
  ++ linuxRuntimeDeps;
  guiNativeBuildInputs = [
    buildPkgs.pkg-config
    buildPkgs.makeWrapper
    nativePkgs.imagemagick
    nativePkgs.zstd
  ];

  # include-flate's proc macro needs native zstd, not the application's ARM
  # library. pkg-config-rs supports separate search paths for each Rust triple.
  buildTriple =
    builtins.replaceStrings [ "-" ] [ "_" ]
      crossPkgs.stdenv.buildPlatform.rust.rustcTarget;
  nativeZstdEnv = {
    "PKG_CONFIG_${buildTriple}" = "${nativePkgs.pkg-config}/bin/pkg-config";
    "PKG_CONFIG_PATH_${buildTriple}" = "${nativePkgs.zstd.dev}/lib/pkgconfig";
    "PKG_CONFIG_LIBDIR_${buildTriple}" = "${nativePkgs.zstd.dev}/lib/pkgconfig";
  };

  upstreamTopq = inputs.topq.packages.${buildSystem}.default;
  upstreamTabulite = inputs.tabulite.packages.${buildSystem}.default;

  # Keep the locked DuckDB 1.5.5 recipe and its Excel/SQLite extension sources.
  # Only its stdenv/tools cross-compile; shared libraries come from the ARM cache.
  duckdb =
    (import "${inputs.tabulite}/duckdb.nix" {
      pkgs = crossPkgs // {
        duckdb = crossPkgs.duckdb.override {
          inherit (armPkgs) openssl;
        };
        inherit (armPkgs)
          expat
          zlib
          minizip-ng
          bzip2
          xz
          zstd
          ;
        inherit (nativePkgs) writeText;
      };
    }).overrideAttrs
      (old: {
        cmakeFlags =
          old.cmakeFlags
          ++ lib.optionals isCross [
            # Otherwise extension metadata generation executes duckdb_platform_binary
            # for ARM on the build host. This also sets the library's platform string.
            (lib.cmakeFeature "DUCKDB_EXPLICIT_PLATFORM" "linux_arm64")
          ];
      });
in
{
  ram = (inputs.ram.overlays.default (crossPkgs // { inherit rustPlatform; }) crossPkgs).ram;

  map = import ./map.nix {
    inherit
      inputs
      nativePkgs
      armPkgs
      crossPkgs
      ;
  };

  topq = rustPlatform.buildRustPackage {
    inherit (upstreamTopq)
      pname
      version
      src
      meta
      cargoDeps
      postInstall
      preCheck
      ;
    nativeCheckInputs = [ nativePkgs.cacert ];
    nativeBuildInputs = guiNativeBuildInputs;
    buildInputs = guiBuildInputs;
    env = nativeZstdEnv;
    postFixup = ''
      wrapProgram $out/bin/topq \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath linuxRuntimeDeps}
    '';
  };

  tabulite = rustPlatform.buildRustPackage {
    inherit (upstreamTabulite)
      pname
      version
      src
      meta
      cargoDeps
      postInstall
      preCheck
      ;
    nativeBuildInputs = guiNativeBuildInputs;
    buildInputs = [
      duckdb.lib
      duckdb.dev
    ]
    ++ guiBuildInputs;
    DUCKDB_LIB_DIR = "${duckdb.lib}/lib";
    DUCKDB_INCLUDE_DIR = "${duckdb.dev}/include";
    env = nativeZstdEnv;
    postFixup = ''
      wrapProgram $out/bin/tabulite \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (linuxRuntimeDeps ++ [ duckdb.lib ])}
    '';
  };

  tabulite-duckdb = duckdb;

  ai-usagebar =
    (crossPkgs.callPackage "${inputs.ai-usagebar}/nix/package.nix" {
      inherit rustPlatform;
      inherit (armPkgs) procps xdg-utils;
      inherit (buildPkgs) makeWrapper;
    }).overrideAttrs
      (old: {
        # Bulk vendoring avoids a remote build and transfer for every unpacked crate.
        cargoDeps = nativePkgs.rustPlatform.fetchCargoVendor {
          inherit (old) pname version src;
          hash = "sha256-ftZPiho44qw9CLiUH5bDERJ3KzVcNMOYOtksxXopEB0=";
        };
      });

  hyprexpose = crossPkgs.callPackage "${inputs.hyprexpose}/default.nix" {
    inherit rustPlatform;
    inherit (armPkgs)
      wayland
      wayland-protocols
      cairo
      pango
      glib
      libxkbcommon
      fontconfig
      ;
    inherit (buildPkgs) pkg-config wayland-scanner;
    # The cross buildPackages variant wraps the scanner in QEMU and pulls in
    # cross-built GLib/Python. Rust uses pregenerated bindings and native tools.
    inherit (nativePkgs) gobject-introspection;
  };
}
