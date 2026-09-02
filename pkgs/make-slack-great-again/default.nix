{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  openssl,
  qt6,
}:
let
  microsoftGsl = fetchFromGitHub {
    owner = "microsoft";
    repo = "GSL";
    tag = "v4.0.0";
    hash = "sha256-cXDFqt2KgMFGfdh6NGE+JmP4R0Wm9LNHM0eIblYe6zU=";
  };

  libRpl = fetchFromGitHub {
    owner = "desktop-app";
    repo = "lib_rpl";
    rev = "c57cccffb01d85570decd7fccb88419c9a682e63";
    hash = "sha256-liYPg5cE502wsLkhMpMVMR7BB9PRxGjMaCxrZ4r6Omk=";
  };

  libBase = fetchFromGitHub {
    owner = "desktop-app";
    repo = "lib_base";
    rev = "82d182a275e197fd717fecc86193d9d91f4fc5b5";
    hash = "sha256-ads7ua3XK6iB0Mg9WrpnO1tEwWzJ3kHsJVOz5qJf/KM=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "make-slack-great-again";
  version = "2026-08-30";

  src = fetchFromGitHub {
    owner = "punarinta";
    repo = "make-slack-great-again";
    tag = finalAttrs.version;
    hash = "sha256-6G/hzBIR2HksNOJbc86p6ZAWXMcBPiZDFf78pmEZTxs=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt6.qttools
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    openssl
    qt6.qtbase
    qt6.qtsvg
    qt6.qtwayland
    qt6.qtwebsockets
  ];

  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_MICROSOFT_GSL=${microsoftGsl}"
    "-DFETCHCONTENT_SOURCE_DIR_LIB_RPL=${libRpl}"
    "-DFETCHCONTENT_SOURCE_DIR_LIB_BASE=${libBase}"
    "-DMSGA_BUILD_TESTS=OFF"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 msga "$out/bin/msga"
    install -Dm644 ${finalAttrs.src}/gfx/msga.desktop \
      "$out/share/applications/msga.desktop"
    install -Dm644 ${finalAttrs.src}/gfx/icon.svg \
      "$out/share/icons/hicolor/scalable/apps/msga.svg"

    runHook postInstall
  '';

  meta = {
    description = "Fast native Slack client built with C++ and Qt 6";
    homepage = "https://github.com/punarinta/make-slack-great-again";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "msga";
    platforms = lib.platforms.linux;
  };
})
