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
        hardware.bluetooth = {
          # Use the bluez package with experimental features for sixaxis plugin
          package = pkgs.bluez;

          settings = {
            General = {
              # Ensure the sixaxis plugin is not excluded
              # ClassicBondedOnly = false;
              FastConnectable = true;
              # Battery level updates require experimental features
              Experimental = true;
            };
          };

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
