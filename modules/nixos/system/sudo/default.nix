{ ... }:
{
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl poweroff";
          options = [ "PASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl reboot";
          options = [ "PASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/shutdown";
          options = [ "PASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/reboot";
          options = [ "PASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/poweroff";
          options = [ "PASSWD" ];
        }
      ];
    }
  ];
}
