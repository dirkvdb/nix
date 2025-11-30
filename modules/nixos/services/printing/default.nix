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
    services.printing = {
      enable = true;

      drivers = [
        (pkgs.linkFarm "drivers" [
          {
            name = "share/cups/model/HP-Photosmart-Prem-C310-series.ppd";
            path = ./printers/HP-Photosmart-Prem-C310-series.ppd;
          }
        ])
        pkgs.gutenprint
      ];
    };

    hardware.printers = {
      ensureDefaultPrinter = "Photosmart-Premium-C310";
      ensurePrinters = [
        {
          name = "Photosmart-Premium-C310";
          location = "Home Office";
          deviceUri = "ipps://192.168.1.15:631/ipp/print";
          model = "HP-Photosmart-Prem-C310-series.ppd";
        }
      ];
    };

    programs.system-config-printer.enable = true;
  };
}
