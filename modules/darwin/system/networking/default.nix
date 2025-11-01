{ userConfig, ... }:
{

  networking.hostName = userConfig.hostname;
  networking.computerName = userConfig.hostname;
}
