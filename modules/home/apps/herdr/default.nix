{
  lib,
  config,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.herdr;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.herdr = {
    enable = lib.mkEnableOption "Herdr terminal agent multiplexer";
  };

  # `herdr` isn't packaged in the pinned stable nixpkgs yet, so pull it from
  # unstablePkgs instead. Drop this once it lands on the stable channel.
  config = lib.mkIf cfg.enable (mkUserHome {
    programs.herdr = {
      enable = true;
      package = unstablePkgs.herdr;
    };
  });
}
