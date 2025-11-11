{ config, ... }:
{

  networking.hostName = config.local.network.hostname;
  networking.computerName = config.local.network.hostname;
}
