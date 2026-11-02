{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  cctools ? null,
  libtiff,
  libpng,
  zlib,
  libwebp,
  libraw,
  openexr,
  openjpeg,
  libjpeg,
  jxrlib,
  pkg-config,
  fixDarwinDylibNames ? null,
  autoSignDarwinBinariesHook ? null,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "freeimage";
  version = "3.19.29";

  src = fetchFromGitHub {
    owner = "danoli3";
    repo = "FreeImage";
    rev = "b6f6b47065140799f24ef01dc20de0a215698f82";
    hash = "sha256-1U63PCN48o5y6nb/uGY4mxLDxUX3lUBN4+cpRSFwBJo=";
  };

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DFREEIMAGE_STATIC=OFF"
    "-DFREEIMAGE_USE_SYSTEM_LIBS=ON"
    "-DCPP_STANDARD=17"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "-DFREEIMAGE_LINUX_PACKAGE_LAYOUT=ON"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
    fixDarwinDylibNames
  ]
  ++ lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [
    autoSignDarwinBinariesHook
  ];
  buildInputs = [
    libtiff
    libpng
    zlib
    libwebp
    libraw
    openexr
    openjpeg
    libjpeg
    jxrlib
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    ln -s $out/lib/libFreeImage.${finalAttrs.version}.dylib $out/lib/libfreeimage.3.dylib
    ln -s libfreeimage.3.dylib $out/lib/libfreeimage.dylib
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Open Source library for accessing popular graphics image file formats";
    homepage = "https://github.com/danoli3/FreeImage";
    license = "GPL";
    maintainers = with lib.maintainers; [ l-as ];
    platforms = with lib.platforms; unix;
  };
})
