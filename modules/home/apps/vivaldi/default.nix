{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  cfg = config.local.apps.vivaldi;
  keepassEnabled = config.local.home-manager.keepassxc.enable;
in
{
  home-manager.users.${user.name} = lib.mkIf cfg.enable {
    xdg.configFile = lib.mkIf (keepassEnabled && isLinux) {
      "vivaldi/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json".text =
      builtins.toJSON {
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
  };
}
