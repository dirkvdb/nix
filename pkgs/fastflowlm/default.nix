{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  boost,
  curl,
  fftw,
  fftwFloat,
  fftwLongDouble,
  ffmpeg,
  readline,
  libuuid,
  libdrm,
  rustPlatform,
  rustc,
  cargo,
  autoPatchelfHook,
  makeWrapper,
  xrt,
}:
stdenv.mkDerivation rec {
  pname = "fastflowlm";
  version = "0.9.42";

  src = fetchFromGitHub {
    owner = "FastFlowLM";
    repo = "FastFlowLM";
    rev = "v${version}";
    hash = "sha256-hEW9snrcZoU1zYQ/IbW4SHAaYujfwnChDORdxWKbDmg=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    name = "${pname}-${version}-cargo-deps";
    inherit src;
    sourceRoot = "${src.name}/third_party/tokenizers-cpp/rust";
    hash = "sha256-NQkrX/fyb1fJUcHmgiO/oTn/DVNkpnBFqp1ugDftJT4=";
    postUnpack = ''
      cp ${./Cargo.lock} $sourceRoot/Cargo.lock
    '';
  };

  sourceRoot = "${src.name}/src";

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    rustc
    cargo
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    boost
    curl
    fftw
    fftwFloat
    fftwLongDouble
    ffmpeg
    readline
    readline.dev
    libuuid
    libdrm
    xrt
    stdenv.cc.cc.lib
  ];

  # XRT libraries may pull in dependencies not available at build time
  autoPatchelfIgnoreMissingDeps = [
    "libxrt_coreutil.so"
  ];

  cmakeFlags = [
    "-GNinja"
    "-DFLM_VERSION=${version}"
    "-DNPU_VERSION=32.0.203.304"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_XCLBIN_PREFIX=${placeholder "out"}/share/flm"
    "-DXRT_INCLUDE_DIR=${xrt}/include"
    "-DXRT_LIB_DIR=${xrt}/lib"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  postUnpack = ''
    chmod -R u+w $sourceRoot/..
    cp ${./Cargo.lock} $sourceRoot/../third_party/tokenizers-cpp/rust/Cargo.lock
  '';

  postPatch = ''
    # Remove the install(CODE) block that creates a /usr/local/bin/flm symlink
    sed -i '/if(NOT WIN32 AND NOT CMAKE_INSTALL_PREFIX/,/^endif()$/d' CMakeLists.txt

    # Fix the output directory to use the build dir instead of source dir
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ''${CMAKE_SOURCE_DIR}/build/)' \
                     'set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ''${CMAKE_BINARY_DIR}/)'
  '';

  # Set up cargo vendoring before cmake runs, since cmake triggers the cargo build
  preConfigure = ''
    export CARGO_HOME="$TMPDIR/cargo-home"
    mkdir -p "$CARGO_HOME"

    mkdir -p ../third_party/tokenizers-cpp/rust/.cargo
    substitute ${cargoDeps}/.cargo/config.toml \
      ../third_party/tokenizers-cpp/rust/.cargo/config.toml \
      --replace-fail "@vendor@" "${cargoDeps}"
  '';

  # Wrap the binary to find XRT libraries at runtime
  postInstall = ''
    wrapProgram "$out/bin/flm" \
      --prefix LD_LIBRARY_PATH : "${xrt}/lib"
  '';

  meta = {
    description = "Run LLMs on AMD Ryzen AI NPUs - like Ollama, but optimized for NPU";
    homepage = "https://github.com/FastFlowLM/FastFlowLM";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "flm";
  };
}
