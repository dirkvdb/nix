{
  config,

  lib,
  pkgs,
  ...
}:
let
  inherit (config.local) user;

in
{
  environment.systemPackages = [
    pkgs.xilo-cli
  ];

  environment.variables.XILO_URL = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 "https://nix-cache.hl.vandenboer.eu";

  nix = {
    settings = {
      trusted-users = [
        "${user.name}"
      ];
      extra-substituters = [
        "https://geo-overlay.cachix.org"
        "https://cache.numtide.com"
        "https://nix-cache.hl.vandenboer.eu/c/admin/nix"
      ];
      extra-trusted-public-keys = [
        "geo-overlay.cachix.org-1:12l/BhbUaHEG9AacDyJnQd8z96djJu0ESRuizUOs758="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix:RbyHddnPSyQ30hzVNRTBt08ZTSpVRMpB4QZeOgxsqKQ="
      ];
    };
  };
}
