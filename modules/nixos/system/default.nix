{
  ...
}:
{
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutAbortSec = "10s"; # optional
  };

  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  documentation.man.cache.enable = false;
}
