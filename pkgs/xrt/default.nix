{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  git,
  boost,
  libdrm,
  elfutils,
  openssl,
  libuuid,
  curl,
  protobuf,
  json-glib,
  ncurses,
  systemdLibs,
  pciutils,
  rapidjson,
  python3,
  ocl-icd,
  opencl-headers,
}:
stdenv.mkDerivation {
  pname = "xrt";
  version = "0-unstable-2025-05-25";

  src = fetchFromGitHub {
    owner = "amd";
    repo = "xdna-driver";
    rev = "0220d14fa02e6220d510e61baa1b130af61f60ed";
    hash = "sha256-8fsm1nlxGZfFF+f3eF1AaTkO+RQmBkEGPiCiD0Ztlok=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    git
    python3
    python3.pkgs.pybind11
  ];

  buildInputs = [
    boost
    libdrm
    elfutils
    openssl
    libuuid
    curl
    protobuf
    json-glib
    ncurses
    systemdLibs
    pciutils
    rapidjson
    ocl-icd
    opencl-headers
    stdenv.cc.cc.lib
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DSKIP_KMOD=1"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  # XRT build uses git for version info; fake it in the sandbox
  preConfigure = ''
    export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
    export HOME=$TMPDIR
  '';

  postPatch = ''
    # Prevent firmware installation to /usr/lib/firmware
    substituteInPlace CMakeLists.txt \
      --replace-quiet '/usr/lib/firmware/amdnpu' "$out/lib/firmware/amdnpu"

    # Provide sys/sdt.h stub (SystemTap DTrace probe markers - no-ops without systemtap)
    mkdir -p $TMPDIR/sdt-include/sys
    cat > $TMPDIR/sdt-include/sys/sdt.h << 'SDTEOF'
    #ifndef _SYS_SDT_H
    #define _SYS_SDT_H
    #define DTRACE_PROBE(...)
    #define DTRACE_PROBE1(...)
    #define DTRACE_PROBE2(...)
    #define DTRACE_PROBE3(...)
    #define DTRACE_PROBE4(...)
    #define STAP_PROBE(...)
    #define STAP_PROBE1(...)
    #define STAP_PROBE2(...)
    #define STAP_PROBE3(...)
    #define STAP_PROBE4(...)
    #define STAP_PROBEV(...)
    #endif
    SDTEOF
    export NIX_CFLAGS_COMPILE="-isystem $TMPDIR/sdt-include $NIX_CFLAGS_COMPILE"

    # Replace distro-specific packaging with minimal version variable setup
    cat > CMake/pkg.cmake << 'PKGEOF'
    set(XRT_PLUGIN_VERSION_STRING "2.19.0")
    set(XRT_SOVERSION 2)
    PKGEOF

    # Redirect test install targets (which write to /bins) to the proper lib dir,
    # so libxrt_core.so and libxrt_coreutil.so end up in $out/lib/
    substituteInPlace src/shim/CMakeLists.txt \
      --replace-quiet 'install(TARGETS ''${XRT_CORE_TARGET} DESTINATION ''${XDNA_BIN_DIR}/''${XDNA_PKG_LIB_DIR})' 'install(TARGETS ''${XRT_CORE_TARGET} LIBRARY DESTINATION ''${XDNA_PKG_LIB_DIR} NAMELINK_SKIP COMPONENT ''${XDNA_COMPONENT})' \
      --replace-quiet 'install(TARGETS ''${XRT_COREUTIL_TARGET} DESTINATION ''${XDNA_BIN_DIR}/''${XDNA_PKG_LIB_DIR})' 'install(TARGETS ''${XRT_COREUTIL_TARGET} LIBRARY DESTINATION ''${XDNA_PKG_LIB_DIR} NAMELINK_SKIP COMPONENT ''${XDNA_COMPONENT})' \
      --replace-quiet 'install(TARGETS ''${XDNA_TARGET} DESTINATION ''${XDNA_BIN_DIR}/''${XDNA_PKG_LIB_DIR})' '# nix: disabled duplicate test install'

    # version.cmake uses git commands that fail in the Nix sandbox
    cat > CMake/version.cmake << 'VEREOF'
    set(XDNA_BRANCH "nix")
    set(XDNA_HASH "0220d14")
    set(XDNA_HASH_DATE "2025-05-25")
    set(XDNA_DATE "20250525")
    set(XDNA_XRT_BRANCH "nix")
    set(XDNA_XRT_HASH "unknown")
    set(XDNA_XRT_HASH_DATE "unknown")
    VEREOF
  '';

  # Fix install layout and add XRT core libraries + headers
  postInstall = ''
    # The install creates a nested path; flatten it
    if [ -d "$out/$out" ]; then
      cp -a "$out/$out/"* "$out/"
      rm -rf "$out/nix"
    fi

    # Create soname symlinks for XRT libraries (cmake NAMELINK_SKIP omits them)
    for lib in "$out"/lib/libxrt_core.so.* "$out"/lib/libxrt_coreutil.so.*; do
      if [ -f "$lib" ]; then
        base=$(basename "$lib")
        soname=$(echo "$base" | sed 's/\.[0-9]*\.[0-9]*$//')
        shortname=$(echo "$base" | sed 's/\.so\..*/\.so/')
        ln -sf "$base" "$out/lib/$soname" 2>/dev/null || true
        ln -sf "$base" "$out/lib/$shortname" 2>/dev/null || true
      fi
    done

    # Install XRT headers
    mkdir -p "$out/include"
    cp -r ../xrt/src/runtime_src/core/include/* "$out/include/"
  '';

  meta = {
    description = "AMD XRT (Xilinx Runtime) and XDNA driver SHIM library";
    homepage = "https://github.com/amd/xdna-driver";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
