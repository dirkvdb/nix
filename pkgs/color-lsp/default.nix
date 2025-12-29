{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "color-lsp";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "huacnlee";
    repo = "color-lsp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-U0pTzW2PCgMxVsa1QX9MC249PXXL2KvRSN1Em2WvIeI=";
  };

  cargoHash = "sha256-etK+9fcKS+y+0C36vJrMkQ0yyVSpCW/DLKg4nTw3LrE=";

  passthru.updateScript = nix-update-script { };

  meta = {
    mainProgram = "color-lsp";
    description = "A document color language server";
    homepage = "https://github.com/huacnlee/color-lsp";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
