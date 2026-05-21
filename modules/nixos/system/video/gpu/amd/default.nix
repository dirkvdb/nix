{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.video.amd;
in
{
  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd # OpenCL ICD loader
          libva # VA-API library
          libvdpau-va-gl # VDPAU via VA-API
        ];
      };

      # AMD GPU firmware
      enableRedistributableFirmware = true;
    };

    environment.systemPackages = with pkgs; [
      rocmPackages.rocm-smi # ROCm SMI
      radeontop # GPU usage monitor
      libva-utils # vainfo and other VA-API utilities
      vulkan-tools # vulkaninfo etc.
      mesa-demos # glxinfo, glxgears etc.
      clinfo # OpenCL info
    ];

    nixpkgs.config.rocmSupport = true;
  };
}
