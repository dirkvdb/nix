{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.system.boot.secureboot;
in
{
  options.local.system.boot.secureboot = {
    enable = lib.mkEnableOption "Enable secure boot";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.boot.loader.systemd-boot.enable;
        message = "Secure boot (lanzaboote) is incompatible with systemd-boot. Disable boot.loader.systemd-boot.enable when using local.system.boot.secureboot.";
      }
    ];

    environment.systemPackages = [
      pkgs.sbctl
    ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
