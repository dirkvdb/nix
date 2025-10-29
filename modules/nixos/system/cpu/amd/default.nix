{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.local.system.cpu.amd;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
  ];

  options.local.system.cpu.amd = {
    enable = lib.mkEnableOption "Enable AMD CPU settings";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      # CPU microcode updates
      cpu.amd.updateMicrocode = true;
    };
  };
}
