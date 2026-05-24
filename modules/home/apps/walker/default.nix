{
  lib,
  config,
  inputs,
  system,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  isDesktop = config.local.desktop.enable or false;
in
{
  config = lib.mkIf isDesktop (mkUserHome {
    home.packages = [
      inputs.elephant.packages.${system}.elephant-with-providers
    ];

    programs.walker = {
      enable = true;
      runAsService = true;
    };
  });
}
