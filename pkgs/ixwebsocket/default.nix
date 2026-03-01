{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "ixwebsocket";
  version = "11.4.4";

  src = fetchFromGitHub {
    owner = "machinezone";
    repo = "IXWebSocket";
    rev = "v${version}";
    hash = "sha256-BLvZBZA9wTvzDuUFXT0YQAEuQxeGyRPxCLuFS4xrknI=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    openssl
    zlib
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DUSE_TLS=ON"
    "-DUSE_ZLIB=ON"
    "-DIXWEBSOCKET_INSTALL=ON"
  ];

  meta = {
    description = "Lightweight C++ WebSocket client/server library";
    homepage = "https://github.com/machinezone/IXWebSocket";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
}
