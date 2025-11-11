{
  lib,
  config,
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
    # On NixOS, use the programs.nh module
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.local.user.name}/nix"; # sets NH_FLAKE variable
    };
  };
}
