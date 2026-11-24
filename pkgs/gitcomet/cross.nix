{
  nixpkgs,
  rust-overlay,
}:
let
  nativePkgs = import nixpkgs {
    system = "x86_64-linux";
    overlays = [ rust-overlay.overlays.default ];
  };
  armPkgs = import nixpkgs { system = "aarch64-linux"; };
  crossPkgs = nativePkgs.pkgsCross.aarch64-multiplatform;
  buildPkgs = crossPkgs.buildPackages;
  rustToolchain = nativePkgs.rust-bin.stable."1.100.0".default.override {
    targets = [ "aarch64-unknown-linux-gnu" ];
  };
  rustPlatform = crossPkgs.makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  gitcomet = crossPkgs.gitcomet.override {
    inherit (armPkgs)
      fontconfig
      freetype
      zlib
      libxcb
      libxkbcommon
      libGL
      vulkan-loader
      wayland
      git
      xdg-utils
      ;
    inherit (buildPkgs) pkg-config desktop-file-utils makeBinaryWrapper;
    inherit rustPlatform;
  };
in
(crossPkgs.callPackage ./default.nix { inherit gitcomet rustPlatform; }).overrideAttrs (old: {
  # GPUI's include-flate proc macro links native zstd, not the ARM library.
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nativePkgs.zstd ];
  env = (old.env or { }) // {
    PKG_CONFIG_x86_64_unknown_linux_gnu = "${nativePkgs.pkg-config}/bin/pkg-config";
    PKG_CONFIG_PATH_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
    PKG_CONFIG_LIBDIR_x86_64_unknown_linux_gnu = "${nativePkgs.zstd.dev}/lib/pkgconfig";
  };
})
