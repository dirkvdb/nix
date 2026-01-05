{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.binfmt;
  isArmLinux = pkgs.stdenv.hostPlatform.isAarch64;

  # Wine with Vulkan and Wayland support enabled
  # Use stagingFull which includes all necessary support libraries
  wineWithVulkan = pkgs.wineWowPackages.stagingFull.override {
    vulkanSupport = true;
    waylandSupport = true;
  };
in
{
  options.local.system.binfmt = {
    enable = lib.mkEnableOption "Enable binary format support for non-native architectures";
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [
      "wasm32-wasi"
    ]
    ++ lib.optionals (!isArmLinux) [
      "x86_64-windows"
    ]
    ++ lib.optionals isArmLinux [
      "x86_64-linux"
    ];

    # Override wine package for Windows executables to include Vulkan and Wayland support
    boot.binfmt.registrations = lib.mkIf (!isArmLinux) {
      x86_64-windows = {
        interpreter = "${wineWithVulkan}/bin/wine";
      };
    };
  };
}
