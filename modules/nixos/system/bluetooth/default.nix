{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.system.bluetooth;
in
{
  options.local.system.bluetooth = {
    enable = lib.mkEnableOption "Enable bluetooth support";
    sixaxis = lib.mkEnableOption "wireless SixAxis (DualShock 3) controller support with high-frequency polling";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;

          settings = {
            General = {
              Experimental = true;
              FastConnectable = true;
              JustWorksRepairing = "always";
              # Reconnect on startup for paired devices
              ReconnectAttempts = 7;
              ReconnectIntervals = "1,2,4,8,16,32,64";
            };
          };
        };

        environment.systemPackages = with pkgs; [
          overskride
          bluetui
        ];
      }

      (lib.mkIf cfg.sixaxis {
        hardware.bluetooth = {
          input = {
            General = {
              # Needed for sixaxis according to arch wiki
              UserspaceHID = false;
              IdleTimeout = 0;
            };
          };
        };

        # udev rules for SixAxis / DualShock 3 controllers
        services.udev.extraRules = ''
          # Sony SixAxis / DualShock 3 — USB (for initial Bluetooth pairing via sixpair)
          SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0660", TAG+="uaccess"

          # Sony SixAxis / DualShock 3 — HID raw device access
          KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0660", TAG+="uaccess"

          # Sony Navigation Controller — USB
          SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="042f", MODE="0660", TAG+="uaccess"

          # Sony Navigation Controller — HID raw device access
          KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="042f", MODE="0660", TAG+="uaccess"
        '';
      })
    ]
  );
}
