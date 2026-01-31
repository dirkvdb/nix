{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  keepassEnabled = config.local.home-manager.keepassxc.enable;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
  isStandalone = config.local.home-manager.standalone or false;
in
{
  config = lib.mkIf (!isHeadless) (
    lib.mkMerge [
      (lib.mkIf (isLinux && isDesktop) (mkUserHome {
        # we always install chromium when on desktop linux because it is used as web app host
        programs.chromium = {
          enable = true;

          extensions = lib.mkIf keepassEnabled [
            "oboonakemofpalcgghocfoadofidjkkk" # keepassxc
          ];

          # widevine support for DRM content (Netflix, Disney+, Spotify, etc)
          package = pkgs.chromium.override { enableWideVine = true; };
        };
      }))

      # KeePassXC native messaging host for Chromium:
      # - In standalone home-manager (e.g. HPC Docker), install in the user XDG config dir.
      #
      # The NixOS system-wide /etc variant lives in `modules/nixos/apps/chromium/default.nix`
      # to avoid referencing NixOS-only options from a home-manager evaluation.
      (lib.mkIf (keepassEnabled && isLinux && isDesktop && isStandalone) (mkUserHome {
        xdg.configFile."chromium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json".text =
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
      }))
    ]
  );
}
