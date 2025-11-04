{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.vscode;

  # # Wrapper script for VS Code that enables libsecret password store
  # # This allows VS Code to use KeePassXC's Secret Service
  # vscodeWrapper = pkgs.writeShellScriptBin "code-wrapped" ''
  #   export LD_LIBRARY_PATH="${pkgs.libsecret}/lib:$LD_LIBRARY_PATH"
  #   exec ${pkgs.vscode}/bin/code --password-store=gnome-libsecret "$@"
  # '';
in

{
  options.local.apps.vscode = {
    enable = lib.mkEnableOption "Install VSCode";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.vscode = {
        enable = true;
        # package = vscodeWrapper;
      };
    };
  };
}
