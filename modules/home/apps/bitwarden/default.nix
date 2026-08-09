{
  lib,
  pkgs,
  config,
  mkHome,
  unstablePkgs,
  system,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.bitwarden;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
  isLinux = lib.hasSuffix "linux" system;
  installDesktop = isLinux && !isHeadless;
in
{
  options.local.apps.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden password manager";
  };

  config = lib.mkIf cfg.enable (
    mkUserHome {
      home.packages =
        [
          pkgs.bitwarden-cli
        ]
        # bitwarden-desktop on the stable channel still bundles an EOL/insecure
        # Electron release; pull it from the unstable channel instead, where
        # it has already been bumped to a supported Electron version.
        ++ lib.optional installDesktop unstablePkgs.bitwarden-desktop;
    }
  );
}
