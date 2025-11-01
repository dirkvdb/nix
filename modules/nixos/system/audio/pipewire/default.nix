{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.audio.pipewire;
in
{
  options.local.system.audio.pipewire = {
    enable = lib.mkEnableOption "Enable PipeWire audio server";

    airplay = lib.mkOption {
      type = lib.types.bool;
      description = "Airplay output support";
    };
  };

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

        # Airplay support
        raopOpenFirewall = cfg.airplay;
        extraConfig.pipewire = lib.mkIf cfg.airplay {
          "10-airplay" = {
            "context.modules" = [
              {
                name = "libpipewire-module-raop-discover";

                # increase the buffer size if you get dropouts/glitches
                # args = {
                #   "raop.latency.ms" = 500;
                # };
              }
            ];
          };
        };

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
