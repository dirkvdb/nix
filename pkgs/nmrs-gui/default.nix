{
  fetchFromGitHub,
  callPackage,
  rustPlatform,
}:
let
  src = fetchFromGitHub {
    owner = "networkmanager-rs";
    repo = "nmrs-gui";
    rev = "65b9e4ca37177e8116c39ac206cbe889bdd8b460";
    hash = "sha256-Dv3jg+v8BQiqDKFzn6RtAGKhbaLsejvEfQ8GFeP+xjo=";
  };
in
callPackage "${src}/package.nix" { inherit rustPlatform; }
