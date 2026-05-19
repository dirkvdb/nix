{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf config.local.system.dev.enable (mkUserHome {
    home.file.".config/devenv/devenv.yaml".text = ''
      devenv:
        warnOnNewVersion: false
    '';
  });
}
