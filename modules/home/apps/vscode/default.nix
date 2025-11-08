{
  lib,
  config,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.vscode;
in
{
  options.local.apps.vscode = {
    enable = lib.mkEnableOption "Install VSCode";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.vscode = {
        enable = true;
      };

      # Force VSCode to use libsecret password store
      # Autodetection fails when using KeePassXC's Secret Service
      home.file.".vscode/argv.json".text = builtins.toJSON {
        enable-crash-reporter = false;
        password-store = "gnome-libsecret";
      };
    };
  };
}
