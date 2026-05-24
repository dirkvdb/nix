{
  ...
}:
{
  services.logind = {
    # make sure the power button does not suspend or shutdown the system, it is handled by hyprland
    settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "ignore";
      #HandlePowerKeyLongPress = "ignore";
      PowerKeyIgnoreInhibited = "yes";
    };
  };
}
