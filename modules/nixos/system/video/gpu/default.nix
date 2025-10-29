{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.local.system.video.amd;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  options.local.system.video.amd = {
    enable = lib.mkEnableOption "Enable AMD graphics support";
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd # OpenCL ICD loader
          rocmPackages.rocm-smi # ROCm System Management Interface
          radeontop
          libva # Video Acceleration API
          libvdpau-va-gl
          vulkan-tools
          glxinfo
          clinfo # Print information about available OpenCL platforms and devices
        ];
      };

      # AMD GPU firmware
      enableRedistributableFirmware = true;

    };
  };
}
