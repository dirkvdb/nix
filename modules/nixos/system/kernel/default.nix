{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  cfg = config.local.system.kernel;
in
{
  options.local.system.kernel = {
    cachyos = {
      enable = lib.mkEnableOption "CachyOS kernel with performance patches";

      cache = lib.mkOption {
        type = lib.types.bool;
        default = cfg.cachyos.enable;
        description = "Add the CachyOS kernel binary cache substituter. Enable separately to prime the cache before switching kernels.";
      };

      variant = lib.mkOption {
        type = lib.types.str;
        default = "linuxPackages-cachyos-latest-lto-zen4";
        description = ''
          The CachyOS kernel variant to use.
          Available variants include:
          - linuxPackages-cachyos-latest (generic)
          - linuxPackages-cachyos-latest-zen4 (Zen 4 optimization)
          - linuxPackages-cachyos-latest-lto (generic + Clang LTO)
          - linuxPackages-cachyos-latest-lto-zen4 (Clang LTO + Zen 4; requires LLVM-compatible out-of-tree modules)
          - linuxPackages-cachyos-latest-lto-x86_64-v3 (Clang LTO + x86_64-v3)
          See https://github.com/xddxdd/nix-cachyos-kernel for all variants.
        '';
      };
    };
  };

  config = lib.mkMerge [
    # Always configure the binary cache so it's available for future builds
    (lib.mkIf cfg.cachyos.cache {
      nix.settings = {
        substituters = [ "https://attic.xuyh0120.win/lantian" ];
        trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
      };
    })

    # Kernel + overlay only when fully enabled
    (lib.mkIf cfg.cachyos.enable {
      nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
      boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.${cfg.cachyos.variant};
    })
  ];
}
