{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "1.0.9";
  baseUrl = "https://github.com/stephansergeev/obsidian-lockstep-sync/releases/download/${version}";
  pluginFiles = [
    (fetchurl {
      url = "${baseUrl}/main.js";
      hash = "sha256-VT0Rh/AXL8rbXENLIyTPlWMrKF+VPzOt5Oq/nuOtbMA=";
    })
    (fetchurl {
      url = "${baseUrl}/manifest.json";
      hash = "sha256-YpXEY8lIXY5oSWAEqjvMkHzeUHo68jOjYqFN9KBdd8k=";
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
