{
  config,
  ...
}:
let
  cfg = config.local.system.network;
in
{
  config = {
    networking.hostName = cfg.hostname;
    networking.computerName = cfg.hostname;
  };
}
