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
  keepassEnabled = config.local.apps.keepassxc.enable;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
  isStandalone = config.local.home-manager.standalone or false;
  proxyPacUrl = config.local.system.network.proxy.pacUrl;

  # Derivation that provides the KeePassXC native messaging host JSON at the
  # path home-manager's chromium module expects: etc/chromium/native-messaging-hosts/.
  # Adding this to programs.chromium.nativeMessagingHosts merges it into the
  # symlink-join that home-manager installs at ~/.config/chromium/NativeMessagingHosts/,
  # so KeePassXC's isBrowserEnabled() check sees the file and shows the checkbox as active.
  keepassxcChromiumHost =
    pkgs.writeTextDir "etc/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
      (
        builtins.toJSON {
          allowed_origins = [
            "chrome-extension://pdffhmdngciaglkoonimfcmckehcpafo/"
            "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
          ];
          description = "KeePassXC integration with native messaging support";
          name = "org.keepassxc.keepassxc_browser";
          path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
          type = "stdio";
        }
      );
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

          commandLineArgs = lib.optionals (proxyPacUrl != null) [
            "--proxy-pac-url=${proxyPacUrl}"
          ];

          # widevine support for DRM content (Netflix, Disney+, Spotify, etc)
          package = pkgs.chromium.override { enableWideVine = true; };
        };
      }))

      # Restore previous session on startup so that session cookies
      # (used by Microsoft Outlook/Teams web apps) survive browser restarts.
      (lib.mkIf (isLinux && isDesktop) {
        programs.chromium = {
          enable = true;
          extraOpts.RestoreOnStartup = 1;
        };
      })

      # KeePassXC native messaging host for Chromium.
      # home-manager's programs.keepassxc module auto-adds pkgs.keepassxc to
      # programs.chromium.nativeMessagingHosts, but the keepassxc package only
      # ships lib/mozilla/…, not etc/chromium/…. We add our own derivation with
      # the JSON at the right path so it gets merged into the symlink-join that
      # home-manager builds for ~/.config/chromium/NativeMessagingHosts/.
      (lib.mkIf (keepassEnabled && isLinux && isDesktop) (mkUserHome {
        programs.chromium.nativeMessagingHosts = [ keepassxcChromiumHost ];
      }))
    ]
  );
}
