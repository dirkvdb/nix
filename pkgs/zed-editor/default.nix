{
  lib,
  stdenv,
  zed-editor,
  fetchFromGitHub,
  rustPlatform,
}:
let
  zedPinnedVersion = "1.28.1";
in
zed-editor.overrideAttrs (old: rec {
  version = zedPinnedVersion;
  doCheck = false;
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  # Zed 1.28 renamed the binary, but the inherited installer uses the old name.
  installPhase =
    if lib.versionAtLeast version "1.28.0" then
      assert lib.assertMsg (lib.hasInfix "$release_target/remote_server" old.installPhase)
        "Zed's upstream install recipe has changed; remove the remote-server installPhase workaround in pkgs/zed-editor/default.nix.";
      builtins.replaceStrings [ "$release_target/remote_server" ] [ "$release_target/remote-server" ]
        old.installPhase
    else
      old.installPhase;
  patches = (old.patches or [ ]) ++ [
    # https://github.com/zed-industries/zed/pull/55857 (adapted for 1.26.2)
    ../../modules/home/apps/zed/wayland-kinetic-scroll.patch
  ];
  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-3FtJA++1yvpAcWgjUrWkRnN/SirfAj66kjQ/iSdrNpQ=";
  };
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${old.pname}-${version}";
    hash = "sha256-1rPsY1UrDAUhe7FlLm2GqTFNzW9XwVP7Lcv7hUcyRdo=";
  };
  env =
    (old.env or { })
    // lib.optionalAttrs stdenv.hostPlatform.isx86_64 {
      NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
    };
})
