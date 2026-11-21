{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.services.eid;
in
{
  options.local.services.eid.enable = lib.mkEnableOption "Belgian eID smart-card support";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.pcscd.enable = true;
        environment.systemPackages = with pkgs; [
          eid-mw
          pcsc-tools
        ];
      }

      (lib.mkIf (user.home-manager.enable && config.local.desktop.enable) (
        mkHome user.name {
          home.file = {
            ".mozilla/managed-storage/belgiumeid@eid.belgium.be.json".source =
              "${pkgs.eid-mw}/lib/mozilla/managed-storage/belgiumeid@eid.belgium.be.json";

            ".mozilla/pkcs11-modules/beidpkcs11.json".source =
              "${pkgs.eid-mw}/lib/mozilla/pkcs11-modules/beidpkcs11.json";

            ".mozilla/pkcs11-modules/beidpkcs11_alt.json".source =
              "${pkgs.eid-mw}/lib/mozilla/pkcs11-modules/beidpkcs11_alt.json";
          };

          programs.firefox.pkcs11Modules = [ pkgs.eid-mw ];
          programs.zen-browser.pkcs11Modules = [ pkgs.eid-mw ];
        }
      ))
    ]
  );
}
