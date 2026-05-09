# Builds the lemonade web-app (React/webpack) that the server serves as its UI.
# The webpack entry-point resolves sources from ../app/src so both src/web-app and src/app
# must be present as siblings. We achieve this by pointing the derivation root at the
# repository root and setting the sub-directory attributes accordingly.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
let
  versionInfo = import ./version.nix;
in
buildNpmPackage {
  pname = "lemonade-web-app-bundle";
  version = versionInfo.version;

  src = fetchFromGitHub {
    owner = versionInfo.src.owner;
    repo = versionInfo.src.repo;
    rev = "v${versionInfo.version}";
    hash = versionInfo.src.hash;
  };

  # package.json and package-lock.json live in src/web-app/
  # but webpack resolves ../app/src/renderer/index.tsx at build time,
  # so we keep the full repo as src and set npmRoot to the sub-directory.
  npmRoot = "src/web-app";

  npmDepsHash = "sha256-PqcaNNEt+V318GKhS6UIHaRF8DHPfM46RgVvAi4HaDU=";

  # Skip lifecycle scripts (postinstall etc.) during npm ci
  npmFlags = [ "--ignore-scripts" ];

  # The npm deps builder looks for package-lock.json at the repo root.
  # Copy it from the sub-directory before the deps phase runs.
  postPatch = ''
    cp src/web-app/package-lock.json package-lock.json
  '';

  preBuild = ''
    # Override the webpack output path to an absolute location we can copy from.
    export WEBPACK_OUTPUT_PATH="$PWD/dist/web-app"
  '';

  buildPhase = ''
    runHook preBuild
    cd src/web-app
    npm run build
    cd ../..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r dist/web-app/. "$out/"
    runHook postInstall
  '';

  meta = {
    description = "Lemonade web-app bundle (React/webpack)";
    homepage = "https://github.com/${versionInfo.src.owner}/${versionInfo.src.repo}";
    license = lib.licenses.mit;
  };
}
