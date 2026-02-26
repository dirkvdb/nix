{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
  electron,
}:
let
  versionInfo = import ./version.nix;
in
buildNpmPackage {
  pname = "lemonade-app";
  version = versionInfo.version;

  src = fetchFromGitHub {
    owner = versionInfo.src.owner;
    repo = versionInfo.src.repo;
    rev = "v${versionInfo.version}";
    hash = versionInfo.src.hash;
  };

  sourceRoot = "source/src/app";

  npmDepsHash = "sha256-N99UajgdTvOILZhIkV/xTZfrpL9uEZWHJqlUSKKUHCU=";

  nativeBuildInputs = [ makeWrapper ];

  # Disable npm install scripts that might try to download binaries
  npmFlags = [ "--ignore-scripts" ];

  # Patch main.js to disable dev tools
  postPatch = ''
    # Comment out the dev tools auto-open
    sed -i 's/mainWindow\.webContents\.openDevTools();/\/\/ mainWindow.webContents.openDevTools();/' main.js
  '';

  # Build the renderer bundle
  buildPhase = ''
    runHook preBuild
    npm run build:renderer:prod
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install app source to be run with electron
    mkdir -p "$out/lib/lemonade-app"
    cp -r dist "$out/lib/lemonade-app/"
    cp -r node_modules "$out/lib/lemonade-app/"
    cp package.json "$out/lib/lemonade-app/"
    cp main.js "$out/lib/lemonade-app/"
    cp preload.js "$out/lib/lemonade-app/"

    # Create wrapper script that launches with electron
    mkdir -p "$out/bin"
    makeWrapper ${electron}/bin/electron "$out/bin/lemonade-app" \
      --add-flags "$out/lib/lemonade-app" \
      --run 'export HF_HOME="''${HOME}/.cache/huggingface"'

    # Copy the icon
    if [ -f "../../data/lemonade-app.svg" ]; then
      mkdir -p "$out/share/pixmaps"
      cp "../../data/lemonade-app.svg" "$out/share/pixmaps/"
    elif [ -f "assets/logo.svg" ]; then
      mkdir -p "$out/share/pixmaps"
      cp "assets/logo.svg" "$out/share/pixmaps/lemonade-app.svg"
    fi

    # Copy desktop file from repository
    if [ -f "../../data/lemonade-app.desktop" ]; then
      mkdir -p "$out/share/applications"
      cp "../../data/lemonade-app.desktop" "$out/share/applications/"
      # Fix Exec path to use the full nix store path and update Name
      substituteInPlace "$out/share/applications/lemonade-app.desktop" \
        --replace-fail "Exec=lemonade-app" "Exec=$out/bin/lemonade-app" \
        --replace-fail "Name=Lemonade App" "Name=Lemonade"
    fi

    runHook postInstall
  '';

  # Electron apps don't need library stripping
  dontStrip = true;

  meta = {
    description = "Lemonade LLM GUI application";
    homepage = "https://github.com/${versionInfo.src.owner}/${versionInfo.src.repo}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "lemonade-app";
  };
}
