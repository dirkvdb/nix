{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
in
{
  environment.systemPackages = [
    inputs.xilo.packages.${pkgs.stdenv.hostPlatform.system}.xilo-cli
  ];

  environment.variables.XILO_URL = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 "https://nix-cache.hl.vandenboer.eu";

  nix = {
    settings = {
      trusted-users = [
        "${user.name}"
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://nix-cache.hl.vandenboer.eu/c/admin/nix"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix:RbyHddnPSyQ30hzVNRTBt08ZTSpVRMpB4QZeOgxsqKQ="
      ];
    };
  };
}
