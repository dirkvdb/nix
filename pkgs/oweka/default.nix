{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "oweka";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "ByteAtATime";
    repo = "oweka";
    tag = "v0.1.3";
    hash = "sha256-h6fHGSX1Slv77PXZV5prqQqT+wTczTr0vbC1ymmT5Ks=";
  };

  cargoHash = "sha256-S5AcTtGwOnF2WEzTVrsVVVjaiVy3JTMzTCjL3qaB2fw=";

  doCheck = false;

  meta = {
    description = "Fast TUI for finding and deleting artifact directories";
    homepage = "https://github.com/ByteAtATime/oweka";
    license = lib.licenses.mit;
    mainProgram = "oweka";
    platforms = lib.platforms.unix;
  };
}
