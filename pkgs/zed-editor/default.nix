{
  lib,
  stdenv,
  zed-editor,
  fetchFromGitHub,
  rustPlatform,
}:
let
  zedPinnedVersion = "1.26.2";
in
zed-editor.overrideAttrs (old: rec {
  version = zedPinnedVersion;
  doCheck = false;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  patches = (old.patches or [ ]) ++ [
    # https://github.com/zed-industries/zed/pull/55857 (adapted for 1.26.2)
    ../../modules/home/apps/zed/wayland-kinetic-scroll.patch
  ];
  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-N0gI3kEYm8CwF82wahzO2RqUpEmmGmN0RTKfBkFnSJE=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${old.pname}-${version}";
    hash = "sha256-TpeNlXZvh0gkjdD7RML5YvHnPOHLsIDgUQMu32K5XTk=";
  };
  env =
    (old.env or { })
    // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
      NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
    };
})
