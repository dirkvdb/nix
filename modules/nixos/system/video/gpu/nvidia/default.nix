{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.video.nvidia;
in
{
  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      # NVIDIA GPU firmware
      enableRedistributableFirmware = true;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia # GPU usage monitor
      libva-utils # vainfo and other VA-API utilities
      vulkan-tools # vulkaninfo etc.
      mesa-demos # glxinfo, glxgears etc.
    ];

    nixpkgs.config.cudaSupport = true;
  };
}
