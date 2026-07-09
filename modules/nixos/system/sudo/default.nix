{ ... }:
{
  # Use sudo-rs, a memory-safe Rust reimplementation of sudo.
  security.sudo.enable = false;
  security.sudo-rs.enable = true;

  security.sudo-rs.extraRules = [
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
