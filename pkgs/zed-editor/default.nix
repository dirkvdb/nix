{
  lib,
  stdenv,
  zed-editor,
  fetchFromGitHub,
  rustPlatform,
}:
let
  zedPinnedVersion = "1.29.1";
in
zed-editor.overrideAttrs (old: rec {
  version = zedPinnedVersion;
  doCheck = false;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  patches = (old.patches or [ ]) ++ [
    ../../modules/home/apps/zed/wayland-kinetic-scroll.patch
  ];
  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-Ez/IEIz5ALLwbE5OiGDd1WgIftR6R3H//v2TdPOIdww=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${old.pname}-${version}";
    hash = "sha256-6nqsXKe4L8mTW88+RgkoACTXPHRrHhzkTDjSr2s5CZk=";
  };
  env =
    (old.env or { })
    // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
      NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
    };
})
