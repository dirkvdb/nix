{ lib, config, ... }:
let
  cfg = config.local.services.tailscale;
in
{
  options.local.services.tailscale.enable = lib.mkEnableOption "Tailscale client";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = lib.mkDefault config.sops.secrets.tailscale_client_secret.path;
      extraUpFlags = [
        "--advertise-tags=tag:nixos"
        "--reset"
      ];
      extraSetFlags = [
        "--operator=${config.local.user.name}"
      ];
    };
  };
}
