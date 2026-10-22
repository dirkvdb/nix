{ inputs }:
let
  nativePkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  armPkgs = import inputs.nixpkgs { system = "aarch64-linux"; };
  crossPkgs = nativePkgs.pkgsCross.aarch64-multiplatform;
  inherit (nativePkgs) lib;

  localPackages = import ./local.nix {
    inherit nativePkgs armPkgs crossPkgs;
  };
  inputPackages = import ./input-apps.nix {
    inherit
      inputs
      nativePkgs
      armPkgs
      crossPkgs
      ;
  };
  crossPackages =
    localPackages
    // inputPackages
    // {
      zed-editor = import ../zed-editor/cross.nix {
        nixpkgs = inputs.nixpkgs-unstable;
      };
    };

  # These exact ARM derivations are already published by llm-agents. Preserve
  # their identities so they substitute upstream rather than rebuilding them.
  cachedPackages = lib.getAttrs [
    "hunk"
    "codex"
    "copilot-cli"
    "herdr"
    "opencode2"
    "opencode2-desktop"
    "chatgpt"
  ] inputs.llm-agents.packages.aarch64-linux;
  packages = crossPackages // cachedPackages;
in
{
  inherit packages;

  # Only user-space application attributes are replaced. Kernels, firmware,
  # system components, NVF and stock nixpkgs packages remain native ARM.
  overlay =
    _final: _prev:
    localPackages
    // (removeAttrs inputPackages [ "tabulite-duckdb" ])
    // {
      zed-editor = crossPackages.zed-editor;
    };

  bundle = nativePkgs.linkFarm "macbook-arm-apps" (
    lib.mapAttrsToList (name: path: { inherit name path; }) packages
  );
}
