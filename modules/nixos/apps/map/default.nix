{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.map;
  inherit (config.hardware.nvidia.prime) offload;
  useNvidiaOffload =
    lib.elem "nvidia" config.services.xserver.videoDrivers && offload.enableOffloadCmd;
  mapPackage =
    if useNvidiaOffload then
      pkgs.symlinkJoin {
        name = "map-nvidia-offload";
        paths = [ pkgs.map ];
        postBuild =
          let
            launcher = pkgs.writeShellScript "map-nvidia-offload" ''
              exec ${lib.escapeShellArg offload.offloadCmdMainProgram} ${pkgs.map}/bin/map "$@"
            '';
          in
          ''
            rm "$out/bin/map"
            ln -s ${launcher} "$out/bin/map"
          '';
      }
    else
      pkgs.map;
  mimeTypes = [
    "application/x-netcdf"
    "image/tiff"
    "image/x-tiff"
  ];
  jsonFormat = pkgs.formats.json { };
  themeFamily = builtins.fromJSON (builtins.readFile ../../../../configs/themes/charcoal-grove.json);
  mapTheme = import ../../../../configs/themes/zed-to-gpui-kit.nix themeFamily;
in
{
  options.local.apps.map.enable = lib.mkEnableOption "Map geospatial data viewer";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ mapPackage ];

    home-manager.users.${config.local.user.name}.xdg = {
      mimeApps = {
        associations.added = lib.genAttrs mimeTypes (_: "map.desktop");
        defaultApplications = lib.genAttrs mimeTypes (_: "map.desktop");
      };

      configFile = {
        "map/config.json".source = jsonFormat.generate "map-config.json" {
          light_theme = "Charcoal Grove Light";
          dark_theme = "Charcoal Grove";
        };
        "map/themes/charcoal-grove.json".source = jsonFormat.generate "map-charcoal-grove.json" mapTheme;
      };
    };
  };
}
