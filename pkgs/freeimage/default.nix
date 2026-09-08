{
  lib,
  stdenv,
  fetchsvn,
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
  version = "unstable-2021-11-01";

  src = fetchsvn {
    url = "svn://svn.code.sf.net/p/freeimage/svn/";
    rev = "1900";
    sha256 = "rWoNlU/BWKZBPzRb1HqU6T0sT7aK6dpqKPe88+o/4sA=";
  };

  sourceRoot = "${finalAttrs.src.name}/FreeImage/trunk";

  # Ensure that the bundled libraries are not used at all
  prePatch = ''
    rm -rf Source/Lib* Source/OpenEXR Source/ZLib
  '';
  patches = [
    ./unbundle.diff
    ./libtiff-4.4.0.diff
  ];

  postPatch =
    ''
      # To support cross compilation, use the correct `pkg-config`.
      substituteInPlace Makefile.fip \
        --replace "pkg-config" "$PKG_CONFIG"
      substituteInPlace Makefile.gnu \
        --replace "pkg-config" "$PKG_CONFIG"

      # FreeImage 3.19 predates the public header locations in current
      # OpenEXR/libtiff releases. The G3 plugin also depends on libtiff's
      # private tiffiop.h, which is no longer installed.
      substituteInPlace Source/FreeImage/PluginEXR.cpp Source/FreeImage/PluginTIFF.cpp \
        --replace-fail "<OpenEXR/half.h>" "<Imath/half.h>"
      substituteInPlace Source/FreeImage/PluginEXR.cpp \
        --replace-fail "Imath::Int64" "uint64_t"
      # These old sources require private libtiff and libjpeg headers that
      # current nixpkgs intentionally does not install. Disable those optional
      # plugins rather than reintroducing bundled copies.
      substituteInPlace Makefile.srcs fipMakefile.srcs \
        --replace-fail "./Source/FreeImage/PluginG3.cpp " "" \
        --replace-fail "./Source/FreeImage/PluginTIFF.cpp " "" \
        --replace-fail "./Source/Metadata/XTIFF.cpp " "" \
        --replace-fail "./Source/FreeImageToolkit/JPEGTransform.cpp " ""
      substituteInPlace Source/FreeImage/Plugin.cpp \
        --replace-fail "s_plugins->AddNode(InitTIFF);" "" \
        --replace-fail "s_plugins->AddNode(InitG3);" ""
    ''
    + lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
      # Upstream Makefile hardcodes i386 and x86_64 architectures only
      substituteInPlace Makefile.osx --replace "x86_64" "arm64"
    '';

  nativeBuildInputs =
    [
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

  postBuild = lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
    make -f Makefile.fip
  '';

  INCDIR = "${placeholder "out"}/include";
  INSTALLDIR = "${placeholder "out"}/lib";

  preInstall =
    ''
      mkdir -p $INCDIR $INSTALLDIR
    ''
    # Workaround for Makefiles.osx not using ?=
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      makeFlagsArray+=( "INCDIR=$INCDIR" "INSTALLDIR=$INSTALLDIR" )
    '';

  postInstall =
    lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
      make -f Makefile.fip install
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      ln -s $out/lib/libfreeimage.3.dylib $out/lib/libfreeimage.dylib
    '';

  enableParallelBuilding = true;

  meta = {
    description = "Open Source library for accessing popular graphics image file formats";
    homepage = "http://freeimage.sourceforge.net/";
    license = "GPL";
    knownVulnerabilities = [
      "CVE-2021-33367"
      "CVE-2021-40262"
      "CVE-2021-40263"
      "CVE-2021-40264"
      "CVE-2021-40265"
      "CVE-2021-40266"

      "CVE-2023-47992"
      "CVE-2023-47993"
      "CVE-2023-47994"
      "CVE-2023-47995"
      "CVE-2023-47996"
    ];
    maintainers = with lib.maintainers; [ l-as ];
    platforms = with lib.platforms; unix;
  };
})
