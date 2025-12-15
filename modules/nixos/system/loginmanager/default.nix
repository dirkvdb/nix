{
  ...
}:
{
  # make sure the power button does not suspend or shutdown the system, it is handled by hyprland
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    #HandlePowerKeyLongPress = "ignore";
    PowerKeyIgnoreInhibited = "yes";
  };
}
