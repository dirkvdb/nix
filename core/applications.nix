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

    (lib.mkIf (isLinux && cfg.gui) {
      environment.systemPackages = with pkgs; [
        ghostty
        nautilus
        file-roller
        glib # for gsettings to work
        gsettings-qt
        gtk-engine-murrine # for gtk themes
        ungoogled-chromium
      ];
    })
  ];
}
