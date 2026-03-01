{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.system.utils;
  hasAmdVideo = config.local.system.video.amd.enable;
  hasDesktop = config.local.desktop.enable or false;
  supportCpuFreqUtils = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  dev = [
    unstablePkgs.ec
    unstablePkgs.codex
  ];
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
  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        age
        nix-ld # required for running certain binaries not meant for NixOS
      ]
      ++ lib.optionals cfg.dev dev
      ++ lib.optionals cfg.sysadmin sysadmin
      ++ lib.optionals (!hasAmdVideo) [
        btop
      ]
      ++ lib.optionals supportCpuFreqUtils [
        cpufrequtils
      ]
      ++ lib.optionals hasAmdVideo [
        btop-rocm
      ];
  };
}
