{
  config,
  lib,
  ...
}:
let
  cfg = config.local.system.network;
in
{
  options.local.system.network = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Device hostname";
    };
  };

  config =  {
    networking.hostName = cfg.hostname;
    networking.computerName = cfg.hostname;
  };
}
