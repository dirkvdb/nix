{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
}:
let
  pname = "es-de";
  isLinuxArm = stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64;
  stableVersion = "3.4.0";
  armPrereleaseVersion = "prerelease-2025-11-20";
  version = if isLinuxArm then armPrereleaseVersion else stableVersion;

  src = fetchurl {
    # The Linux AArch64 AppImage is currently published as an experimental prerelease.
    url =
      if isLinuxArm then
        "https://gitlab.com/es-de/emulationstation-de/-/package_files/248914983/download"
      else
        "https://gitlab.com/es-de/emulationstation-de/-/package_files/246875981/download";
    hash =
      if isLinuxArm then
        "sha256-fKuGqk4QQlLmjpPX4atKTd9zYj0U5j4Sb8fKLmpVY5M="
      else
        "sha256-TLZs/JIwmXEc+g7d2D22R0SmKU4C4//Rnuhn93qI7H4=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 \
      ${appimageContents}/usr/share/applications/org.es_de.frontend.desktop \
      $out/share/applications/org.es_de.frontend.desktop

    install -Dm444 \
      ${appimageContents}/usr/share/icons/hicolor/scalable/apps/org.es_de.frontend.svg \
      $out/share/icons/hicolor/scalable/apps/org.es_de.frontend.svg
  '';

  meta = with lib; {
    description = "ES-DE Frontend (EmulationStation Desktop Edition)";
    homepage = "https://es-de.org/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "es-de";
  };
}
