{
  ...
}:
{
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutAbortSec = "10s"; # optional
    DefaultLimitMEMLOCK = "infinity";
  };

  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
    DefaultLimitMEMLOCK=infinity
  '';

  documentation.man.cache.enable = false;
}
