{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.homepage-dashboard;
in
{
  options.services.homepage-dashboard.quadletEntries = lib.mkOption {
    type = lib.types.attrsOf (pkgs.formats.yaml { }).type;
    default = { };
    description = "Homepage entries contributed by enabled Quadlet modules.";
  };

  config = lib.mkIf (cfg.enable && cfg.quadletEntries != { }) {
    services.homepage-dashboard.services = [
      {
        Quadlets = lib.mapAttrsToList (name: entry: { ${name} = entry; }) cfg.quadletEntries;
      }
    ];
  };
}
