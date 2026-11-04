{
  lib,
  stdenv,
  zed-editor,
  fetchFromGitHub,
  rustPlatform,
}:
let
  zedPinnedVersion = "1.27.0";
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
    hash = "sha256-pYT/+23XPsXpkErUVIqlKS3cKPyE7LMtj6rnSl+NqXY=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${old.pname}-${version}";
    hash = "sha256-SomjXacn8S8EIMqmE4UFWrUXWTudSXvWGIIXZarbIV0=";
  };
  env =
    (old.env or { })
    // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
      NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
    };
})
