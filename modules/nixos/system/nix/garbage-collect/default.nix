{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.nix.garbageCollect;
in
{
  options.local.system.nix.garbageCollect = {
    enable = lib.mkEnableOption "Enable Nix garbage collection";
  };

  config = lib.mkIf cfg.enable {
    nix.gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 1w";
    };
  };
}
