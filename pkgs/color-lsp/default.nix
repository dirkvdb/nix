{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "color-lsp";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "huacnlee";
    repo = "color-lsp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-m26eIA+K5ERmmlDaX6gJp+ABL4bLnsQF/R8A+tzmpZw=";
  };

  cargoHash = "sha256-RUQmjM/DLBrsvn9/1BnP0V7VduP4UHrmnPiqUhzFimo=";

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "color-lsp";
    description = "A document color language server";
    homepage = "https://github.com/huacnlee/color-lsp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
