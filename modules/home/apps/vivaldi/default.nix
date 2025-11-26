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
  options.local.apps.vivaldi = {
    enable = lib.mkEnableOption "Enable Vivaldi home-manager configuration";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
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
  };
}
