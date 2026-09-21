{ lib, stdenvNoCC, fetchurl }:

let
  pluginFiles = [
    (fetchurl {
      url = "https://github.com/cooklang/cooklang-obsidian/releases/download/0.13.0/main.js";
      hash = "sha256-pMhL5uDNIN05dsJj50ARkDJDljGDcOFoDbz5K/YmO90=";
    })
    (fetchurl {
      url = "https://github.com/cooklang/cooklang-obsidian/releases/download/0.13.0/manifest.json";
      hash = "sha256-UmrZ26BkXxI1Su09rLhpNz89B2cw2UyNj6V4m/fyHoc=";
    })
    (fetchurl {
      url = "https://github.com/cooklang/cooklang-obsidian/releases/download/0.13.0/styles.css";
      hash = "sha256-DSjOXvvOZy0dnpf5E8RHp64SzahP3MHG4IU4UKudWkI=";
    })
  ];
in
stdenvNoCC.mkDerivation {
  pname = "obsidian-cooklang";
  version = "0.13.0";
  srcs = pluginFiles;
  dontUnpack = true;

  installPhase = ''
    install -Dm644 ${builtins.elemAt pluginFiles 0} $out/main.js
    install -Dm644 ${builtins.elemAt pluginFiles 1} $out/manifest.json
    install -Dm644 ${builtins.elemAt pluginFiles 2} $out/styles.css
  '';

  meta = {
    description = "Cooklang recipe support for Obsidian";
    homepage = "https://github.com/cooklang/cooklang-obsidian";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
