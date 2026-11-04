{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
let
  version = "1.18.2";
  cargoFlags = [
    "-p"
    "localsend-cli"
  ];
in
rustPlatform.buildRustPackage {
  pname = "localsend-cli";
  inherit version;

  src = fetchFromGitHub {
    owner = "localsend";
    repo = "localsend";
    tag = "v${version}";
    hash = "sha256-hP4whBkBQ/FEnUOjgeC+HIzrWhtbME6HGxmwwvTSSeI=";
  };

  cargoHash = "sha256-lgg+f7gLHUG4pYUAJW+nIrS8vUX4x+daupgCG8jct/Q=";
  cargoBuildFlags = cargoFlags;
  cargoInstallFlags = cargoFlags;
  doCheck = false;

  postInstall = ''
    install -Dm644 LICENSE $out/share/licenses/localsend-cli/LICENSE
  '';

  meta = {
    description = "Official terminal client for LocalSend";
    homepage = "https://github.com/localsend/localsend/tree/v${version}/cli";
    license = lib.licenses.asl20;
    mainProgram = "localsend-cli";
    platforms = lib.platforms.linux;
  };
}
