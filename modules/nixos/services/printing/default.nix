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
          {
            name = "share/cups/model/HP/HP-LaserJet-MFP-M426fdw.ppd";
            path = ./printers/HP-LaserJet-MFP-M426fdw.ppd;
          }
        ])
        pkgs.gutenprint
        pkgs.hplip
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
        {
          name = "HP-LaserJet-MFP-M426fdw";
          location = "Office";
          deviceUri = "ipp://192.168.1.45/ipp/print";
          model = "HP/HP-LaserJet-MFP-M426fdw.ppd";
          ppdOptions = { InputSlot = "Tray2"; };
        }
      ];
    };

    programs.system-config-printer.enable = true;
  };
}
