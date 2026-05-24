{
  ...
}:
{
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "suspend";

    # make sure the power button does not suspend or shutdown the system, it is handled by hyprland
    settings.Login = {
      HandlePowerKey = "ignore";
      #HandlePowerKeyLongPress = "ignore";
      PowerKeyIgnoreInhibited = "yes";
    };
  };
}
