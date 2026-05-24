{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:

(buildGoModule.override { go = go_1_26; }) (finalAttrs: {
  pname = "hyprmoncfg";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "crmne";
    repo = "hyprmoncfg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KA8w53Qjf08/nMTBEWLdmBABlwnlidIf237cmYfFQiQ=";
  };

  vendorHash = "sha256-gQbjvdKtO0hCXrs9RnWo1s0YeHf5W9t+8AgS2ELXlPo=";

  doCheck = false;

  meta = {
    description = "Arrange Hyprland monitors without coordinate math";
    homepage = "https://github.com/crmne/hyprmoncfg";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "hyprmoncfg";
    platforms = lib.platforms.linux;
  };
})
