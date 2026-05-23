{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.cpu;
in
{
  options.local.system.cpu = {
    disableMitigations = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.hostPlatform.isx86;
      description = ''
        Disable CPU vulnerability mitigations (Spectre, Meltdown, etc.)
        for better performance on trusted/home machines.
      '';
    };
  };

  config = lib.mkIf cfg.disableMitigations {
    boot.kernelParams = [ "mitigations=off" ];
  };
}
