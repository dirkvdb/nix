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
          rocmPackages.rocm-smi # ROCm SMI
          radeontop
          libva
          libvdpau-va-gl
          vulkan-tools
          mesa-demos # provides `glxinfo`
          clinfo
        ];
      };

      # AMD GPU firmware
      enableRedistributableFirmware = true;
    };

    nixpkgs.config.rocmSupport = true;
  };
}
