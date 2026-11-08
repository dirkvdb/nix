{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.kernel;
  kernel = config.boot.kernelPackages.kernel;
  kernelOutputs = map (
    output: builtins.unsafeDiscardStringContext (toString kernel.${output})
  ) kernel.outputs;
  pushSystemClosure = pkgs.writeShellScriptBin "nixcfg-push-system" ''
    set -euo pipefail
    system=/run/current-system
    ${
      if !cfg.native then
        ''exec xilo push admin/nix "$system"''
      else
        ''
          work="$(mktemp -d)"
          trap 'rm -rf "$work"' EXIT
          export LC_ALL=C
          nix-store --query --requisites "$system" | sort -u > "$work/closure"
          printf '%s\n' ${lib.escapeShellArgs kernelOutputs} | sort -u > "$work/kernel-outputs"
          comm -12 "$work/closure" "$work/kernel-outputs" > "$work/excluded"
          if [ ! -s "$work/excluded" ]; then
            echo "Native kernel outputs not found in the system closure; refusing to upload." >&2
            exit 1
          fi

          # Xilo recursively uploads dependencies, so exclude every transitive referrer too.
          xargs -r nix-store --query --referrers-closure < "$work/excluded" | sort -u > "$work/referrers"
          comm -23 "$work/closure" "$work/referrers" > "$work/upload"
          if [ -s "$work/upload" ]; then
            echo "Uploading system dependencies that do not reference the native kernel."
            xilo push admin/nix - < "$work/upload"
          fi
        ''
    }
  '';
in
{
  options.local.system.kernel = {
    useLatest = lib.mkEnableOption "the latest available kernel (pkgs.linuxPackages_latest) instead of the default nixpkgs kernel";
    native = lib.mkEnableOption ''
      building the kernel with -march=native. This targets the build machine's CPU,
      so build locally on the deployment machine
    '';
  };

  config = lib.mkMerge [
    { environment.systemPackages = [ pushSystemClosure ]; }
    (lib.mkIf (cfg.useLatest || cfg.native) {
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
    })
  ];
}
