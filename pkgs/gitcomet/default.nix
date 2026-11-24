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
    version = "0.3.5";
    src = fetchFromGitHub {
      owner = "Auto-Explore";
      repo = "GitComet";
      tag = "v${finalAttrs.version}";
      hash = "sha256-3vIrMChrGuYnHH3qb6wy2DN1OdTAI7b5n4Dv+7iqs7Y=";
    };
    doCheck = false;
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      name = "gitcomet-${finalAttrs.version}";
      hash = "sha256-voheMv1RZFjEzkrnLDVWhz2Me+5JovB0Bi/lxp08pWE=";
    };
  }
  // lib.optionalAttrs (stdenv.buildPlatform != stdenv.hostPlatform) {
    doInstallCheck = false;
  }
)
