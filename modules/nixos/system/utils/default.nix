{
  lib,
  config,
  pkgs,
  options,
  ...
}:
let
  cfg = config.local.system.utils;
  hasAmdVideo = config.local.system.video.amd.enable or false;
  hasDesktop = config.local.desktop.enable or false;
  dev = [ ];
  sysadmin =
    with pkgs;
    [
      usbutils
    ]
    ++ lib.optionals hasDesktop [
      gparted
    ];
in
{
  # options.local.system.utils = {
  #   enable = lib.mkOption {
  #     type = lib.types.bool;
  #     default = true;
  #     description = "Enable installation of common system utilities.";
  #   };

  #   dev = lib.mkEnableOption "Developer-focused tooling (e.g., mise, just)";
  #   sysadmin = lib.mkEnableOption "Sysadmin-focused tooling (bind, killall, usbutils on Linux)";
  # };

  config = lib.mkIf options.local.system.utils.enable {
    environment.systemPackages =
      with pkgs;
      [
        cpufrequtils
        nix-ld # required for running certain binaries not meant for NixOS
      ]
      ++ lib.optionals cfg.dev dev
      ++ lib.optionals cfg.sysadmin sysadmin
      ++ lib.optionals (!hasAmdVideo) [
        btop
      ]
      ++ lib.optionals hasAmdVideo [
        btop-rocm
      ];
  };
}
