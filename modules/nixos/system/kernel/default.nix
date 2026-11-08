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
  };

  config = lib.mkIf cfg.useLatest {
    boot.kernelPackages = pkgs.linuxPackages_latest.extend (
      _final: prev: {
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
