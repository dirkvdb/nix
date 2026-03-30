{
  lib,
  config,
  pkgs,
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
        hardware.bluetooth.enable = true;

        environment.systemPackages = with pkgs; [
          overskride
        ];
      }

      (lib.mkIf cfg.sixaxis {
        # Load the hid_sony kernel module for SixAxis/DualShock 3 protocol support
        boot.kernelModules = [ "hid_sony" ];

        # High-frequency USB polling (1ms = 1000Hz) for when the controller is
        # plugged in via USB (required for initial Bluetooth pairing)
        boot.kernelParams = [ "usbhid.jspoll=1" ];

        hardware.bluetooth = {
          # Use the bluez package with experimental features for sixaxis plugin
          package = pkgs.bluez;

          settings = {
            General = {
              # Ensure the sixaxis plugin is not excluded
              ClassicBondedOnly = false;
              FastConnectable = true;
            };

            # Lower connection intervals for reduced input latency over Bluetooth
            # Units are in 1.25ms increments (6 = 7.5ms, 9 = 11.25ms)
            LE = {
              MinConnectionInterval = 6;
              MaxConnectionInterval = 9;
              ConnectionLatency = 0;
            };
          };

          input = {
            General = {
              # Process HID events in userspace for better compatibility
              UserspaceHID = true;
              # Never disconnect idle controllers
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
