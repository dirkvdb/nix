{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.whatsapp;
in
{
  options.local.apps.whatsapp = {
    enable = lib.mkEnableOption "Install whatsapp";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (if pkgs.stdenv.isDarwin then pkgs.whatsapp-for-mac else pkgs.whatsapp-electron)
    ];
  };
}
