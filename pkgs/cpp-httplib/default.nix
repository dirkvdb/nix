{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "cpp-httplib";
  version = "0.34.0";

  src = fetchFromGitHub {
    owner = "yhirose";
    repo = "cpp-httplib";
    rev = "v${version}";
    hash = "sha256-FEfaSn89WIrm1fOsVqpaJK8fkHsCb6J2+6gKktyAxqs=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    openssl
    zlib
  ];

  cmakeFlags = [
    "-DHTTPLIB_REQUIRE_OPENSSL=ON"
    "-DHTTPLIB_REQUIRE_ZLIB=ON"
    "-DBUILD_SHARED_LIBS=OFF"
  ];

  meta = {
    description = "A C++ header-only HTTP/HTTPS server and client library";
    homepage = "https://github.com/yhirose/cpp-httplib";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
