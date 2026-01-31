{
  lib,
  config,
  pkgs,
  ...
}:
let
  # `modules/home/*` is also used for standalone home-manager (e.g. HPC Docker).
  # Keep NixOS-only options like `environment.*` out of that evaluation.
  keepassEnabled = lib.attrByPath [ "local" "home-manager" "keepassxc" "enable" ] false config;
  isDesktop = lib.attrByPath [ "local" "desktop" "enable" ] false config;
  isHeadless = lib.attrByPath [ "local" "headless" ] false config;
  isStandalone = lib.attrByPath [ "local" "home-manager" "standalone" ] false config;
in
{
  config =
    lib.mkIf (pkgs.stdenv.isLinux && isDesktop && (!isHeadless) && keepassEnabled && (!isStandalone))
      {
        # KeePassXC native messaging host for Chromium:
        # install system-wide in /etc to avoid issues when $HOME/.config is symlinked/ephemeral.
        environment.etc."chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text =
          builtins.toJSON
            {
              allowed_origins = [
                "chrome-extension://pdffhmdngciaglkoonimfcmckehcpafo/"
                "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
              ];
              description = "KeePassXC integration with native messaging support";
              name = "org.keepassxc.keepassxc_browser";
              path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
              type = "stdio";
            };
      };
}
