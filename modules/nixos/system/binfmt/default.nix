{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.system.binfmt;
  isArmLinux = pkgs.stdenv.hostPlatform.isAarch64;
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
  };
}
