{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.nixCfg.applications;
  isLinux = pkgs.stdenv.isLinux;
in
{
  # Application options (enable/gui/dev) moved to nix/core/default.nix for consistency.

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        bitwarden
        sqlitebrowser
        sublime-merge
        spotify
      ];
    })

    (lib.mkIf (isLinux && cfg.gui) {
      environment.systemPackages = with pkgs; [
        ghostty
        nautilus
        glib # for gsettings to work
        gsettings-qt
        gtk-engine-murrine # for gtk themes
        ungoogled-chromium
      ];
    })

    (lib.mkIf (isLinux && cfg.dev) {
      environment.systemPackages = with pkgs; [
        mise
        just
      ];
    })
  ];
}
