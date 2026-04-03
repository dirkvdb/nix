{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  xmlstarlet,
  gettext,
  ffmpeg,
  freetype,
  harfbuzz,
  icu,
  libgit2,
  curl,
  pugixml,
  SDL2,
  alsa-lib,
  bluez,
  libGL,
  lunasvg,
  poppler,
  rlottie,
  freeimage,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "es-de";
  version = "3.4.0";

  src = fetchurl {
    url = "https://gitlab.com/es-de/emulationstation-de/-/archive/v${finalAttrs.version}/emulationstation-de-v${finalAttrs.version}.tar.bz2";
    hash = "sha256-S3nNtSimJlQAWyX62/nDlV58RWFcSqgQhHc7BU20d2U=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    gettext
    xmlstarlet
  ];

  buildInputs = [
    ffmpeg
    freeimage
    freetype
    gettext
    harfbuzz
    icu
    libgit2
    curl
    pugixml
    SDL2
    alsa-lib
    bluez
    libGL
    lunasvg
    poppler
    rlottie
  ];

  cmakeFlags = [
    "-DAPPLICATION_UPDATER=off"
  ];

  postInstall = ''
    systems_dir="$out/share/es-de/resources/systems/linux"
    find_rules="$systems_dir/es_find_rules.xml"
    systems_xml="$systems_dir/es_systems.xml"

    # Append an EDEN emulator detection block for Linux.
    sed -i 's|</ruleList>|    <emulator name="EDEN">\n        <!-- Nintendo Switch emulator Eden -->\n        <rule type="systempath">\n            <entry>eden-cli</entry>\n        </rule>\n        <rule type="staticpath">\n            <entry>~/Applications/*eden*.AppImage</entry>\n            <entry>~/.local/share/applications/*eden*.AppImage</entry>\n            <entry>~/.local/bin/*eden*.AppImage</entry>\n            <entry>~/bin/*eden*.AppImage</entry>\n            <entry>~/.local/bin/eden-cli</entry>\n            <entry>~/bin/eden-cli</entry>\n        </rule>\n    </emulator>\n</ruleList>|' \
      "$find_rules"

    # Add an EDEN launch command for the Nintendo Switch system.
    # Use eden-cli with -f (fullscreen) and -g (game path).
    xmlstarlet ed --inplace \
      -s "/systemList/system[name='switch']" -t elem -n command -v "%EMULATOR_EDEN% -f -g %ROM%" \
      "$systems_xml"

    xmlstarlet ed --inplace \
      -i "/systemList/system[name='switch']/command[text()='%EMULATOR_EDEN% -f -g %ROM%'][not(@label)]" \
      -t attr -n label -v "Eden (Standalone)" \
      "$systems_xml"
  '';

  meta = with lib; {
    description = "ES-DE Frontend (EmulationStation Desktop Edition)";
    homepage = "https://es-de.org/";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "es-de";
  };
})
