{ config, lib, ... }:
let
  cfg = config.nixCfg.docker;
in
{

  config = lib.mkIf cfg.enable {
    # enable containerization ( docker )
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
