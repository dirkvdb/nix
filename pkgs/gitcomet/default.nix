{
  lib,
  stdenv,
  gitcomet,
  fetchFromGitHub,
  rustPlatform,
}:
gitcomet.overrideAttrs (
  finalAttrs: _:
  {
    version = "0.3.4";
    src = fetchFromGitHub {
      owner = "Auto-Explore";
      repo = "GitComet";
      tag = "v${finalAttrs.version}";
      hash = "sha256-zBlJI6n9/Gb/8Fl17DwFUCginvij8KKyOT2eFsc4J0U=";
    };
    doCheck = false;
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      name = "gitcomet-${finalAttrs.version}";
      hash = "sha256-VlkSQiL9oyL6b+KUNWFL/4MuL5cq2Mkm+BAy2hUewq0=";
    };
  }
  // lib.optionalAttrs (stdenv.buildPlatform != stdenv.hostPlatform) {
    doInstallCheck = false;
  }
)
