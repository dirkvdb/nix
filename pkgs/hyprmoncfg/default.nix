{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
  installShellFiles,
}:

(buildGoModule.override { go = go_1_26; }) (finalAttrs: {
  pname = "hyprmoncfg";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "crmne";
    repo = "hyprmoncfg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hu3ekA4wAp83DE2v00B2n5gsZt2iSv0/OWbg5Mwo4gY=";
  };

  vendorHash = "sha256-gQbjvdKtO0hCXrs9RnWo1s0YeHf5W9t+8AgS2ELXlPo=";

  nativeBuildInputs = [ installShellFiles ];

  doCheck = false;

  postInstall = ''
    install -Dm644 packaging/systemd/hyprmoncfgd.service $out/lib/systemd/user/hyprmoncfgd.service
    substituteInPlace $out/lib/systemd/user/hyprmoncfgd.service \
      --replace-fail '/usr/bin/hyprmoncfgd' "$out/bin/hyprmoncfgd"

    install -Dm644 packaging/applications/hyprmoncfg.desktop $out/share/applications/hyprmoncfg.desktop
    install -Dm644 packaging/icons/hyprmoncfg.svg $out/share/icons/hicolor/scalable/apps/hyprmoncfg.svg

    installShellCompletion --cmd hyprmoncfg \
      --bash <($out/bin/hyprmoncfg completion bash) \
      --fish <($out/bin/hyprmoncfg completion fish) \
      --zsh <($out/bin/hyprmoncfg completion zsh)
  '';

  meta = {
    description = "Arrange Hyprland monitors without coordinate math";
    homepage = "https://github.com/crmne/hyprmoncfg";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "hyprmoncfg";
    platforms = lib.platforms.linux;
  };
})
