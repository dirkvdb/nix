{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixCfg.audio;
in
{

  config = lib.mkIf cfg.enable {
    # enable the RealtimeKit system service, required by PipeWire for low-latency audio
    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      pamixer
      wiremix
    ];

    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = false;

        # prevent the alsa audio devices from getting suspended after a timeout
        # which causes you to miss the first second of audio playback
        # thus missing notification sounds
        wireplumber.configPackages = [
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/alsa.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    device.name = "~alsa_card.*"
                  }
                ]
                actions = {
                  update-props = {
                    # Device settings
                    api.alsa.use-acp = true
                  }
                }
              }
              {
                matches = [
                  {
                    node.name = "~alsa_input.pci*"
                  }
                  {
                    node.name = "~alsa_output.pci*"
                  }
                ]
                actions = {
                # Node settings
                  update-props = {
                    session.suspend-timeout-seconds = 0
                  }
                }
              }
            ]
          '')
        ];
      };
    };
  };
}
