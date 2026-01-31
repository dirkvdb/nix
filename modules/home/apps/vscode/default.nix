{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.vscode;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.vscode = {
    enable = lib.mkEnableOption "Install VSCode";
  };

  config = lib.mkIf (cfg.enable && !isHeadless) (mkUserHome {
    programs.vscode = {
      enable = true;
    };

    # Force VSCode to use libsecret password store
    # Autodetection fails when using KeePassXC's Secret Service
    home.file.".vscode/argv.json".text = builtins.toJSON {
      enable-crash-reporter = false;
      password-store = "gnome-libsecret";
    };
  });
}
