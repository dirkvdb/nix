{
  inputs,
  nativePkgs,
  armPkgs,
  crossPkgs,
}:
let
  inherit (nativePkgs) lib;
  buildPkgs = crossPkgs.buildPackages;
  upstream = inputs.map.packages.${nativePkgs.stdenv.hostPlatform.system}.default;
  geoPkgs = import inputs.nixpkgs {
    localSystem = nativePkgs.stdenv.hostPlatform.system;
    crossSystem = armPkgs.stdenv.hostPlatform.system;
    overlays = [
      inputs.map.inputs.rust-overlay.overlays.default
      (inputs.map.inputs.pkgs-mod.lib.mkOverlay { static = true; })
    ];
  };
  libuvPkgConfig = nativePkgs.runCommand "map-arm-libuv-pkgconfig" { } ''
    mkdir -p $out/lib/pkgconfig
    ln -s ${lib.getDev geoPkgs.pkg-mod-libuv}/lib/pkgconfig/libuv-static.pc $out/lib/pkgconfig/libuv.pc
  '';
  runtimeDeps = with armPkgs; [
    fontconfig
    libxcb
    libxkbcommon
    wayland
    vulkan-loader
    libglvnd
  ];
  buildTriple =
    builtins.replaceStrings [ "-" ] [ "_" ]
      crossPkgs.stdenv.buildPlatform.rust.rustcTarget;
  targetTriple =
    builtins.replaceStrings [ "-" ] [ "_" ]
      crossPkgs.stdenv.hostPlatform.rust.rustcTarget;
in
crossPkgs.rustPlatform.buildRustPackage {
  inherit (upstream)
    pname
    version
    src
    cargoDeps
    postPatch
    postInstall
    dontUseCmakeConfigure
    dontUseNinjaBuild
    dontUseNinjaCheck
    dontUseNinjaInstall
    MLN_PRECOMPILE
    ;

  strictDeps = true;
  doCheck = false;
  doInstallCheck = false;
  nativeBuildInputs = [
    buildPkgs.pkg-config
    buildPkgs.cmake
    buildPkgs.ninja
    buildPkgs.git
    buildPkgs.python3
    buildPkgs.makeWrapper
    nativePkgs.imagemagick
    nativePkgs.zstd
  ];
  buildInputs = [
    armPkgs.fontconfig.dev
    armPkgs.vulkan-headers
    armPkgs.zstd
    libuvPkgConfig
  ]
  ++ runtimeDeps
  ++ (with geoPkgs; [
    pkg-mod-gdal
    pkg-mod-proj
    pkg-mod-curl
    pkg-mod-libwebp
    pkg-mod-libpng
    pkg-mod-libjpeg
    pkg-mod-sqlite
    pkg-mod-openssl
    pkg-mod-zlib-compat
    pkg-mod-libuv
  ]);

  # Build scripts (including webgpu-shim) also compile for the build machine.
  # Keep their compiler, bindgen headers and zstd metadata separate from ARM.
  env = {
    LIBCLANG_PATH = "${nativePkgs.llvmPackages.libclang.lib}/lib";
    "CC_${buildTriple}" = "${nativePkgs.stdenv.cc}/bin/cc";
    "CXX_${buildTriple}" = "${nativePkgs.stdenv.cc}/bin/c++";
    "CC_${targetTriple}" = "${crossPkgs.stdenv.cc}/bin/${crossPkgs.stdenv.cc.targetPrefix}cc";
    "CXX_${targetTriple}" = "${crossPkgs.stdenv.cc}/bin/${crossPkgs.stdenv.cc.targetPrefix}c++";
    "BINDGEN_EXTRA_CLANG_ARGS_${buildTriple}" = "-isystem ${lib.getDev nativePkgs.glibc}/include";
    "BINDGEN_EXTRA_CLANG_ARGS_${targetTriple}" = "-isystem ${lib.getDev armPkgs.glibc}/include";
    "PKG_CONFIG_${buildTriple}" = "${nativePkgs.pkg-config}/bin/pkg-config";
    "PKG_CONFIG_PATH_${buildTriple}" = "${nativePkgs.zstd.dev}/lib/pkgconfig";
    "PKG_CONFIG_LIBDIR_${buildTriple}" = "${nativePkgs.zstd.dev}/lib/pkgconfig";
    MLN_CMAKE_PYTHON_EXECUTABLE = "${buildPkgs.python3}/bin/python3";
  };

  postFixup = ''
    wrapProgram $out/bin/map \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDeps}
  '';
}
