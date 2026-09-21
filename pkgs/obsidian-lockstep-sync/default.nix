{ lib, stdenvNoCC, fetchurl }:

let
  pluginFiles = [
    (fetchurl {
      url = "https://github.com/stephansergeev/obsidian-lockstep-sync/releases/download/1.0.8/main.js";
      hash = "sha256-qtktq2NGrNsy1LHv8nlFDpP8Hfup6lSxzaHRJ295y7Y=";
    })
    (fetchurl {
      url = "https://github.com/stephansergeev/obsidian-lockstep-sync/releases/download/1.0.8/manifest.json";
      hash = "sha256-MDLqu9Qi97CH0gHSht0EIty4vnfrECqpRvVcMN2lAA8=";
    })
    (fetchurl {
      url = "https://github.com/stephansergeev/obsidian-lockstep-sync/releases/download/1.0.8/styles.css";
      hash = "sha256-MHNmaHDK9c7itpLPzS9SQNtFzmMxSMiUWC4luvZvHFU=";
    })
  ];
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-lockstep-sync";
  version = "1.0.8";

  srcs = pluginFiles;
  dontUnpack = true;

  installPhase = ''
    install -Dm644 ${builtins.elemAt pluginFiles 0} $out/main.js
    install -Dm644 ${builtins.elemAt pluginFiles 1} $out/manifest.json
    install -Dm644 ${builtins.elemAt pluginFiles 2} $out/styles.css
  '';

  meta = {
    description = "Self-hosted, end-to-end encrypted sync plugin for Obsidian";
    homepage = "https://community.obsidian.md/plugins/lockstep-sync";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
