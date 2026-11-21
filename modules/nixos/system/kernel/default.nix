{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.kernel;

in
{
  options.local.system.kernel = {
    useLatest = lib.mkEnableOption "the latest available kernel (pkgs.linuxPackages_latest) instead of the default nixpkgs kernel";
    native = lib.mkEnableOption ''
      building the kernel with -march=native. This targets the build machine's CPU,
      so build locally on the deployment machine
    '';
  };

  config = lib.mkIf (cfg.useLatest || cfg.native) {
    boot.kernelPackages =
      (if cfg.useLatest then pkgs.linuxPackages_latest else pkgs.linuxPackages).extend
        (
          _final: prev:
          lib.optionalAttrs cfg.native {
            kernel =
              (prev.kernel.override (old: {
                extraMakeFlags = (old.extraMakeFlags or [ ]) ++ [ "KCFLAGS=-march=native" ];
              })).overrideAttrs
                (_: {
                  preferLocalBuild = true;
                  allowSubstitutes = false;
                  nativeKernelHost = config.networking.hostName;
                });
          }
          // lib.optionalAttrs cfg.useLatest {
            zenpower = prev.zenpower.overrideAttrs (old: {
              # Newer kernels no longer expose CPUID helpers through the AMD headers.
              postPatch = (old.postPatch or "") + ''
                if [ -f ${prev.kernel.dev}/lib/modules/${prev.kernel.modDirVersion}/source/arch/x86/include/asm/cpuid/api.h ]; then
                  substituteInPlace zenpower.c \
                    --replace-fail '#include <linux/version.h>' '#include <linux/version.h>
                #include <asm/cpuid/api.h>'
                fi
              '';
            });
          }
        );
  };
}
