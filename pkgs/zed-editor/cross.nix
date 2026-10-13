{ nixpkgs }:
let
  nativePkgs = import nixpkgs { system = "x86_64-linux"; };
  armPkgs = import nixpkgs { system = "aarch64-linux"; };
  crossPkgs = nativePkgs.pkgsCross.aarch64-multiplatform;
  buildPkgs = crossPkgs.buildPackages;

  # Reuse cached native ARM libraries instead of cross-building WebRTC and its
  # dependency tree. Only Zed and its build scripts need to be compiled here.
  zed-editor = crossPkgs.zed-editor.override {
    inherit (armPkgs)
      libgit2
      sqlite
      zlib
      zstd
      fontconfig
      openssl
      glib
      alsa-lib
      libxkbcommon
      wayland
      libxcb
      libGL
      libx11
      libxext
      livekit-libwebrtc
      vulkan-loader
      bubblewrap
      ;

    # Assemble cached ARM Node.js, npm and Corepack using x86 tools.
    nodejs = armPkgs.nodejs.override { symlinkJoin = nativePkgs.symlinkJoin; };

    # These execute during the build. Cross-aware hooks must still generate ARM
    # wrappers and use ARM pkg-config metadata, despite running on x86.
    inherit (buildPkgs)
      envsubst
      cmake
      protobuf
      cargo-about
      pkg-config
      makeBinaryWrapper
      ;
  };
in
(crossPkgs.callPackage ./default.nix {
  inherit zed-editor;
}).overrideAttrs
  (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ nativePkgs.zstd ];
    # include-flate's procedural macro links zstd on the build machine, while the
    # editor links it on ARM. Cargo's pkg-config crate supports per-triple paths.
    env = old.env // {
      PKG_CONFIG_x86_64_unknown_linux_gnu = "${nativePkgs.pkg-config}/bin/pkg-config";
      PKG_CONFIG_PATH_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
      PKG_CONFIG_LIBDIR_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
    };
  })
