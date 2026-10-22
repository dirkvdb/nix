{ lib, config, ... }:
{
  options.local.system.nix.armCache.enable = lib.mkEnableOption "the shared ARM application cache";

  config = lib.mkIf config.local.system.nix.armCache.enable {
    nix.settings = {
      extra-substituters = [ "https://nix-cache.hl.vandenboer.eu/c/admin/aarch64" ];
      extra-trusted-public-keys = [ "aarch64:GXmlBw2l2lzWB3cMzNJZ3mpkyAtNaT5z1WaOK9Qcmow=" ];
    };
  };
}
