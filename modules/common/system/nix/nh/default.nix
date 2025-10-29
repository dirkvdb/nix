{
  lib,
  config,
  userConfig,
  ...
}:
let
  cfg = config.local.system.nix.nh;
in
{
  options.local.system.nix.nh = {
    enable = lib.mkEnableOption "Enable Nix CLI helper";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${userConfig.username}/nix"; # sets NH_OS_FLAKE variable
    };
  };
}
