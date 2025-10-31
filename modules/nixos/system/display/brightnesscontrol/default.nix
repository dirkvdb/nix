{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.display.brightnesscontrol;
in
{
  options.local.system.display.brightnesscontrol = {
    enable = lib.mkEnableOption "Enable display brightness control";

    i2cDevice = lib.mkOption {
      type = lib.types.str;
      description = "Name of i2c display device";
      example = "i2c-1";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;
    services.ddccontrol.enable = true;

    services = {
      udev.extraRules = ''
        # Give access to i2c devices (needed for monitor brightness control)
        KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
      '';
    };

    systemd.services."ddcci-attach-${cfg.i2cDevice}" = {
      description = "Attach ddcci driver to ${cfg.i2cDevice} for external monitor backlight";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      before = [ "shutdown.target" ];
      conflicts = [ "shutdown.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo ddcci 0x37 > /sys/bus/i2c/devices/${cfg.i2cDevice}/new_device || true'";
        ExecStop = "${pkgs.bash}/bin/bash -c 'if [ -e /sys/bus/i2c/devices/${cfg.i2cDevice}/delete_device ]; then echo 0x37 > /sys/bus/i2c/devices/${cfg.i2cDevice}/delete_device 2>/dev/null || true; fi'";
      };
    };

    environment.systemPackages = with pkgs; [
      brightnessctl
    ];
  };
}
