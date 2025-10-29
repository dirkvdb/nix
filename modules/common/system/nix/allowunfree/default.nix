{ lib, config, ... }:
let
  cfg = config.local.system.nix.unfree;
in
{
  options.local.system.nix.unfree = {
    enable = lib.mkEnableOption "Enable Unfree packages";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
  };

}
