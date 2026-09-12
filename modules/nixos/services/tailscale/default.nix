{ lib, config, ... }:
let
  cfg = config.local.services.tailscale;
in
{
  options.local.services.tailscale.enable = lib.mkEnableOption "Tailscale client";

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
