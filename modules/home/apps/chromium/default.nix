{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  keepassEnabled = config.local.home-manager.keepassxc.enable;
in
{
  home-manager.users.${user.name} = lib.mkIf (isLinux && isDesktop) {
    # we always install chromium when on desktop linux because it is used as web app host
    programs.chromium = {
      enable = true;

      extensions = lib.mkIf keepassEnabled [
        "oboonakemofpalcgghocfoadofidjkkk" # keepassxc
      ];

      # widevine support for DRM content (Netflix, Disney+, Spotify, etc)
      package = pkgs.chromium.override { enableWideVine = true; };
    };
  };

  # System-wide native messaging host for KeePassXC + Chromium
  # Installed system wide to avoid conflicts with home-manager managef config directory
  environment.etc = lib.mkIf (keepassEnabled && isLinux && isDesktop) {
    "chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".text = builtins.toJSON {
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
