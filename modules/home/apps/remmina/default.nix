{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.remmina;
  mkUserHome = mkHome user.name;

  mkConnection =
    name: conn:
    let
      settings = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") conn);
    in
    {
      name = "remmina/${name}.remmina";
      value.text = ''
        [remmina]
        colordepth = 99;
        resolution_mode = 1;
        quality = 2;
        network = "autodetect";
        sound = "off";
        ignore-tls-errors = 1;
        ${settings}
      '';
    };
in
{
  options.local.apps.remmina = {
    enable = lib.mkEnableOption "Remmina remote desktop client connections";

    connections = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      description = "Remmina connection profiles keyed by filename (without .remmina)";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages = [ pkgs.remmina ];
    xdg.dataFile = lib.mapAttrs' mkConnection cfg.connections;
  });
}
