{ lib, config, ... }:
let
  cfg = config.local.services.docker;
in
{
  options.local.services.docker = {
    enable = lib.mkEnableOption "Enable docker service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      libvirtd.enable = true;
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    };
  };
}
