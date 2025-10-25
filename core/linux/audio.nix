{
  config,
  pkgs,
  ...
}:
{
  # enable the RealtimeKit system service, required by PipeWire for low-latency audio
  security.rtkit.enable = true;

  services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };
  };
}
