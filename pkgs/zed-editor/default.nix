{
  lib,
  stdenv,
  zed-editor,
  fetchFromGitHub,
  rustPlatform,
}:
let
  zedPinnedVersion = "1.25.2";
in
zed-editor.overrideAttrs (old: rec {
  version = zedPinnedVersion;
  doCheck = false;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  patches = (old.patches or [ ]) ++ [
    # https://github.com/zed-industries/zed/pull/55857 (adapted for 1.25.1)
    ../../modules/home/apps/zed/wayland-kinetic-scroll.patch
  ];
  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-xrQonXmu/7J7qgk+nai32pIonWrILS1c54Dcj0JN2Bg=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${old.pname}-${version}";
    hash = "sha256-QFbmkmMp0yzmV3XQVssfALJJrL8njaecTFtGbRG4RP0=";
  };
  env =
    (old.env or { })
    // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
      NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
    };
})
