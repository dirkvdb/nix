{ lib, config, ... }:
let
  cfg = config.local.services.ssh;
in
{
  options.local.services.ssh = {
    enable = lib.mkEnableOption "Enable SSH server";
  };

  config = lib.mkIf cfg.enable {
    services = {
      openssh.enable = true;
    };
  };
}
