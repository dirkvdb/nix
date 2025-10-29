{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.input.keyboard;
in
{
  options.local.system.input.keyboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keyboard settings.";
    };

    via = lib.mkEnableOption "Support for VIA-configurable keyboards";
  };

  config = lib.mkIf cfg.enable {
    services = {
      udev.extraRules = ''
        # Give group hidraw RW access to all hidraw devices (needed for via keyboards)
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="hidraw"
      '';
    };
  };
}
