{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "1.0.8";
  baseUrl = "https://github.com/stephansergeev/obsidian-lockstep-sync/releases/download/${version}";
  pluginFiles = [
    (fetchurl {
      url = "${baseUrl}/main.js";
      hash = "sha256-qtktq2NGrNsy1LHv8nlFDpP8Hfup6lSxzaHRJ295y7Y=";
    })
    (fetchurl {
      url = "${baseUrl}/manifest.json";
      hash = "sha256-MDLqu9Qi97CH0gHSht0EIty4vnfrECqpRvVcMN2lAA8=";
    })
    (fetchurl {
      url = "${baseUrl}/styles.css";
      hash = "sha256-MHNmaHDK9c7itpLPzS9SQNtFzmMxSMiUWC4luvZvHFU=";
    })
  ];
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-lockstep-sync";
  inherit version;

  srcs = pluginFiles;
  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 ${builtins.elemAt pluginFiles 0} "$out/main.js"
    install -Dm644 ${builtins.elemAt pluginFiles 1} "$out/manifest.json"
    install -Dm644 ${builtins.elemAt pluginFiles 2} "$out/styles.css"

    runHook postInstall
  '';

  passthru.manifestId = "lockstep-sync";

  meta = {
    description = "Self-hosted, end-to-end encrypted sync plugin for Obsidian";
    homepage = "https://github.com/stephansergeev/obsidian-lockstep-sync";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
