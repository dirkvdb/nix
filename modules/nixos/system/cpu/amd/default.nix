{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.cpu.amd;
in
{
  options.local.system.cpu.amd = {
    enable = lib.mkEnableOption "Enable AMD CPU settings";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      # CPU microcode updates
      cpu.amd.updateMicrocode = true;
      enableRedistributableFirmware = true;
    };
  };
}
