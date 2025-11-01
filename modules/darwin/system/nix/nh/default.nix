{
  lib,
  config,
  pkgs,
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
    # On Darwin, just install the package since programs.nh doesn't exist
    environment.systemPackages = [ pkgs.nh ];

    # Set environment variables for nh on Darwin
    environment.variables = {
      NH_FLAKE = "/Users/${userConfig.username}/.config/nix";
    };
  };
}
