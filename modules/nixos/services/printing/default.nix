{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.services.printing;
in
{
  options.local.services.printing = {
    enable = lib.mkEnableOption "Enable printing with CUPS";
  };

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;

    services.printing.drivers = [ pkgs.gutenprint ];

    # Optional but recommended: Allow network printer discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };

    programs.system-config-printer.enable = true;
  };
}
