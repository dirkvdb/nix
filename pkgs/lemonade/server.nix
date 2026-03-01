{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  git,
  makeWrapper,
  pkg-config,
  llama-cpp-rocm ? null,
  stable-diffusion-cpp-rocm ? null,
  openssl,
  elfutils,
  rocmPackages,
  # System dependencies to avoid FetchContent
  nlohmann_json,
  curl,
  zstd,
  cli11,
  cpp-httplib,
  ixwebsocket,
}:
let
  versionInfo = import ./version.nix;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lemonade-server";
  version = versionInfo.version;

  src = fetchFromGitHub {
    owner = versionInfo.src.owner;
    repo = versionInfo.src.repo;
    rev = "v${versionInfo.version}";
    hash = versionInfo.src.hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    git
    makeWrapper
    pkg-config
    elfutils
  ];

  buildInputs = [
    openssl
    stdenv.cc.cc.lib
    rocmPackages.clr
    rocmPackages.rocm-runtime
    rocmPackages.rocblas
    rocmPackages.hipblas
    # System dependencies to avoid FetchContent
    nlohmann_json
    curl
    zstd
    cli11
    cpp-httplib
    ixwebsocket
  ];

  # Set CMAKE_PREFIX_PATH and PKG_CONFIG_PATH to help find dependencies
  preConfigure = ''
    export CMAKE_PREFIX_PATH="${
      lib.concatStringsSep ":" [
        nlohmann_json
        curl.dev
        zstd.dev
        cli11
        cpp-httplib
        ixwebsocket
      ]
    }"
    export PKG_CONFIG_PATH="${
      lib.concatStringsSep ":" [
        "${curl.dev}/lib/pkgconfig"
        "${zstd.dev}/lib/pkgconfig"
      ]
    }"
  '';

  cmakeFlags = [
    "-GNinja"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_DATADIR=share"
    # Force use of system dependencies instead of FetchContent
    "-DUSE_SYSTEM_JSON=ON"
    "-DUSE_SYSTEM_CURL=ON"
    "-DUSE_SYSTEM_ZSTD=ON"
    "-DUSE_SYSTEM_CLI11=ON"
    "-DUSE_SYSTEM_HTTPLIB=ON"
    # Help CMake find cpp-httplib via its CMake config
    "-Dhttplib_DIR=${cpp-httplib}/lib/cmake/httplib"
    # Help CMake find ixwebsocket via its CMake config
    "-Dixwebsocket_DIR=${ixwebsocket}/lib/cmake/ixwebsocket"
  ];

  # Build only the server components
  buildPhase = ''
    runHook preBuild
    ninja -j $NIX_BUILD_CORES
    runHook postBuild
  '';

  # Prevent installation to /usr paths and fix cpp-httplib linking
  postPatch = ''
    # Remove any hardcoded /usr paths from CMakeLists.txt
    substituteInPlace CMakeLists.txt \
      --replace-fail '/usr/bin' "''${out}/bin" \
      --replace-fail '/usr/lib' "''${out}/lib" \
      --replace-fail '/usr/share' "''${out}/share" \
      --replace-fail '/etc/lemonade' "''${out}/etc/lemonade" || true

    # v9.4.1 declares IXWebSocket via FetchContent on Linux but gates include(FetchContent)
    # behind USE_SYSTEM_* flags. Ensure FetchContent is included for Linux/Windows too.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
      'if(NOT USE_SYSTEM_JSON OR NOT USE_SYSTEM_CURL OR NOT USE_SYSTEM_ZSTD OR NOT USE_SYSTEM_CLI11 OR NOT USE_SYSTEM_HTTPLIB)' \
      'if(NOT USE_SYSTEM_JSON OR NOT USE_SYSTEM_CURL OR NOT USE_SYSTEM_ZSTD OR NOT USE_SYSTEM_CLI11 OR NOT USE_SYSTEM_HTTPLIB OR WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Linux")'

    # Replace IXWebSocket FetchContent usage with system package lookup.
    sed -i '/^# === IXWebSocket (for WebSocket support: Windows and Linux) ===$/,/^endif()$/c\
    # === IXWebSocket (for WebSocket support: Windows and Linux) ===\
    if(WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Linux")\
        find_package(ixwebsocket CONFIG REQUIRED)\
        message(STATUS "Using system IXWebSocket package")\
    endif()' CMakeLists.txt

    # Link against exported CMake target from system ixwebsocket package.
    sed -i 's/target_link_libraries(\$'{EXECUTABLE_NAME}' PRIVATE ixwebsocket)/target_link_libraries(\$'{EXECUTABLE_NAME}' PRIVATE ixwebsocket::ixwebsocket)/g' CMakeLists.txt

    # Add find_package(httplib) after the pkg_check_modules line in root CMakeLists.txt
    sed -i '/pkg_check_modules(HTTPLIB QUIET cpp-httplib/a find_package(httplib QUIET)' CMakeLists.txt

    # Replace the conditional httplib linking with always using the CMake target in all CMakeLists.txt files
    find . -name CMakeLists.txt -exec sed -i \
      -e 's/target_link_libraries(\$'{EXECUTABLE_NAME}' PRIVATE cpp-httplib)/target_link_libraries(\$'{EXECUTABLE_NAME}' PRIVATE httplib::httplib)/g' \
      -e 's/target_link_libraries(lemonade-server PRIVATE cpp-httplib)/target_link_libraries(lemonade-server PRIVATE httplib::httplib)/g' \
      -e 's/target_link_libraries(lemonade-router PRIVATE cpp-httplib)/target_link_libraries(lemonade-router PRIVATE httplib::httplib)/g' \
      {} +

    # Also check for install commands
    find . -name CMakeLists.txt -exec sed -i \
      -e 's|/usr/bin|''${CMAKE_INSTALL_PREFIX}/bin|g' \
      -e 's|/usr/lib|''${CMAKE_INSTALL_PREFIX}/lib|g' \
      -e 's|/usr/share|''${CMAKE_INSTALL_PREFIX}/share|g' \
      {} +
  '';

  # Fix reflexive symlinks after installation
  postInstall = ''
    # Fix reflexive symlink to lemonade-server if it exists
    if [ -L "$out/bin/lemonade-server" ] && [ ! -e "$out/bin/lemonade-server" ]; then
      # If it's a broken symlink, likely pointing to itself, create proper symlink to router
      rm "$out/bin/lemonade-server"
      ln -s lemonade-router "$out/bin/lemonade-server"
    fi

    # Fix reflexive symlink for systemd service if it exists
    if [ -L "$out/lib/systemd/system/lemonade-server.service" ] && [ ! -e "$out/lib/systemd/system/lemonade-server.service" ]; then
      # If the service file is a broken symlink, we need to investigate the actual file
      # For now, if it's reflexive, just remove it - the NixOS module will handle it
      rm "$out/lib/systemd/system/lemonade-server.service"
      rmdir "$out/lib/systemd/system" 2>/dev/null || true
      rmdir "$out/lib/systemd" 2>/dev/null || true
      rmdir "$out/lib" 2>/dev/null || true
    fi

    # Create symlink from bin/resources to share/lemonade-server/resources
    # so lemonade-server can find its resources relative to the binary
    ln -s "$out/share/lemonade-server/resources" "$out/bin/resources"

    # Wrap binaries to set environment variables for backend binaries if provided
    ${lib.optionalString (llama-cpp-rocm != null || stable-diffusion-cpp-rocm != null) ''
      for bin in $out/bin/lemonade-server $out/bin/lemonade-router; do
        if [ -f "$bin" ] && [ ! -L "$bin" ]; then
          mv "$bin" "$bin.unwrapped"
          makeWrapper "$bin.unwrapped" "$bin" \
            ${
              lib.optionalString (
                llama-cpp-rocm != null
              ) ''--set LEMONADE_LLAMACPP_ROCM_BIN "${llama-cpp-rocm}/bin/llama-server"''
            } \
            ${lib.optionalString (
              stable-diffusion-cpp-rocm != null
            ) ''--set LEMONADE_SDCPP_ROCM_BIN "${stable-diffusion-cpp-rocm}/bin/sd-server"''}
        fi
      done
    ''}
  '';

  meta = {
    description = "Lemonade LLM server";
    homepage = "https://github.com/${versionInfo.src.owner}/${versionInfo.src.repo}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "lemonade-server";
  };
})
