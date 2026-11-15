{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  bitwarden-cli,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lazybw";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "SyscallBrain";
    repo = "lazybw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-pVH4eU6/O3QlJJAYxabZyaO8BEN7zhIBY/R/YoCMr38=";
  };

  cargoHash = "sha256-tOytYXygByYLP6o7hoRzSEf4cqhwHELs8BgFt1DdJ0Y=";

  nativeBuildInputs = [ makeWrapper ];

  cargoBuildFlags = [
    "-p"
    "lazybw"
  ];
  cargoInstallFlags = finalAttrs.cargoBuildFlags;

  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/lazybw \
      --prefix PATH : ${lib.makeBinPath [ bitwarden-cli ]}
  '';

  meta = {
    description = "Keyboard-first terminal UI for the Bitwarden vault";
    homepage = "https://github.com/SyscallBrain/lazybw";
    license = lib.licenses.mit;
    mainProgram = "lazybw";
    platforms = lib.platforms.linux;
  };
})
